/**
 * @file lr-mtmd-cli.cpp
 *
 * @brief C++ adapter for llama.cpp
 *
 * Wraps up the llama.cpp multimodal code so it can be used as a C++ class
 *
 * @author Created by Geoff G. on 05/25/2025 based on code from llama.cpp mtmd
 *
 * @attention This example code is subject to change as llama multimodal continues to
 * evolve, and is therefore not production ready
 *
 */

#include "arg.h"
#include "log.h"
#include "common.h"
#include "sampling.h"
#include "llama.h"
#include "ggml.h"
#include "console.h"
#include "chat.h"
#include "mtmd.h"
#include "mtmd-helper.h"

#include <vector>
#include <limits.h>
#include <cinttypes>

#include <signal.h>
#include <unistd.h>

#include "lr-mtmd-cli-shared.h"
#include "lr-mtmd-cli-callback.h"
#include "lr-mtmd-cli.h"
#include "lr-mtmd-cli-errors.h"

// Callback used by the class
bool (*lr_mtmd_cli_callback)(void *,
                             LlamarattiEvent,
                             const char *);

// Default callback if the user doesn't supply one
bool default_lr_mtmd_cli_callback(void *vmtmd,
                                  LlamarattiEvent event,
                                  const char *piece);

/**
 * @brief mtmd_cli_context
 *
 */
struct mtmd_cli_context {
    
    mtmd::context_ptr ctx_vision;
    common_init_result llama_init;

    llama_model       * model;
    llama_context     * lctx;
    const llama_vocab * vocab;
    common_sampler    * smpl;
    llama_batch         batch;
    int                 n_batch;

    mtmd::bitmaps bitmaps;

    // note: we know that gemma3 template is "linear", meaning each turn is completely separated to another
    // so here we don't need to keep track of chat history
    common_chat_templates_ptr tmpls;

    // support for legacy templates (models not having EOT token)
    llama_tokens antiprompt_tokens;

    int n_threads    = 1;
    llama_pos n_past = 0;

    mtmd_cli_context(common_params & params) : llama_init(common_init_from_params(params)) {
        model = llama_init.model.get();
        lctx = llama_init.context.get();
        vocab = llama_model_get_vocab(model);
        smpl = common_sampler_init(model, params.sampling);
        n_threads = params.cpuparams.n_threads;
        batch = llama_batch_init(1, 0, 1); // batch for next token generation
        n_batch = params.n_batch;

        if (!model || !lctx) {
            exit(1);
        }

        if (!llama_model_chat_template(model, nullptr) && params.chat_template.empty()) {
            LOG_ERR("Model does not have chat template.\n");
            LOG_ERR("  For old llava models, you may need to use '--chat-template vicuna'\n");
            LOG_ERR("  For MobileVLM models, use '--chat-template deepseek'\n");
            LOG_ERR("  For Mistral Small 3.1, use '--chat-template mistral-v7'\n");
            exit(1);
        }

        tmpls = common_chat_templates_init(model, params.chat_template);
        LOG_INF("%s: chat template example:\n%s\n", __func__, common_chat_format_example(tmpls.get(), params.use_jinja).c_str());

        init_vision_context(params);

        // load antiprompt tokens for legacy templates
        if (params.chat_template == "vicuna") {
            antiprompt_tokens = common_tokenize(lctx, "ASSISTANT:", false, true);
        } else if (params.chat_template == "deepseek") {
            antiprompt_tokens = common_tokenize(lctx, "###", false, true);
        }
    }

    ~mtmd_cli_context() {
        llama_batch_free(batch);
        common_sampler_free(smpl);
    }

    void init_vision_context(common_params & params) {
        const char * clip_path = params.mmproj.path.c_str();
        mtmd_context_params mparams = mtmd_context_params_default();
        mparams.use_gpu = params.mmproj_use_gpu;
        mparams.print_timings = true;
        mparams.n_threads = params.cpuparams.n_threads;
        mparams.verbosity = params.verbosity > 0 ? GGML_LOG_LEVEL_DEBUG : GGML_LOG_LEVEL_INFO;
        ctx_vision.reset(mtmd_init_from_file(clip_path, model, mparams));
        if (!ctx_vision.get()) {
            
            auto args = std::make_format_args(__func__, clip_path);
            std::string err=std::vformat(gErrMtmdLoadVisionModel, args);
            LOG_ERR("%s\n", err.c_str());
            //lr_mtmd_cli_callback(this, Lr_mtmd_cli_event_status,err.c_str());

            exit(1);
        }
    }

    bool check_antiprompt(const llama_tokens & generated_tokens) {
        if (antiprompt_tokens.empty() || generated_tokens.size() < antiprompt_tokens.size()) {
            return false;
        }
        return std::equal(
            generated_tokens.end() - antiprompt_tokens.size(),
            generated_tokens.end(),
            antiprompt_tokens.begin()
        );
    }

    bool load_media(const std::string & fname) {
        mtmd::bitmap bmp(mtmd_helper_bitmap_init_from_file(ctx_vision.get(), fname.c_str()));
        if (!bmp.ptr) {
            return false;
        }
        bitmaps.entries.push_back(std::move(bmp));
        return true;
    }
};

/**
 * @brief Constructor
 *
 */
lr_mtmd_cli::lr_mtmd_cli() {
    
    _vctx=NULL;
    _is_generating=false;
    _is_interrupted=false;
    _is_first_msg=false;
    _n_predict=0;
    lr_mtmd_cli_callback=NULL;
    _context="";
}

/**
 * @brief Destructor
 *
 */
lr_mtmd_cli::~lr_mtmd_cli() {
    
    deinit();
}

/**
 * @brief Initializes this adapter
 *
 * @param path_model - path to the model
 * @param path_mmproj - path to the model projector
 * @param is_vision_supported - (returned) whether vision is supported
 * @param is_audio_supported - (returned) whether audio is supported
 * @param context_len - the context length for the model
 * @param temp - temperature for the model
 * @param seed - seed for the model - LLAMA_DEFAULT_SEED = randomize
 * @param user_callback - callback function for receiving events
 *
 * @return The status of the operation
 */
int lr_mtmd_cli::init(char *path_model,
                      char *path_mmproj,
                      bool *is_vision_supported,
                      bool *is_audio_supported,
                      uint32_t context_len,
                      float temp,
                      uint32_t seed,
                      bool (*user_callback)(void *,LlamarattiEvent, const char *)) {
    
    // Did the user provide their own callback?
    if ( user_callback ) {
        // Yes, use it
        lr_mtmd_cli_callback = user_callback;
        LOG_INF("Using user-supplied events callback\n");
        
    } else {
        // No, use default
        lr_mtmd_cli_callback = default_lr_mtmd_cli_callback;
        LOG_INF("Using default events callback\n");
    }

    // Did we get the parameters we need?
    if ( !is_valid_string(path_model) ||
         !is_valid_string(path_mmproj) ||
         is_vision_supported == NULL ||
         is_audio_supported == NULL ) {
        
        // No, outta here...
        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdParams, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());

        return GGML_STATUS_FAILED;
    }
    
    _is_interrupted = false;
    
    ggml_time_init();
    
    common_params params;
    params.sampling.temp = temp; // 0.2 will lower temp by default for better quality
    params.sampling.seed = seed; // LLAMA_DEFAULT_SEED is default (random)
    
    auto args = std::make_format_args(context_len);
    std::string context_len_str=std::vformat("{}", args);
    char *argv[]={
        NULL,
        (char *)"--model",
        path_model,
        (char *)"--mmproj",
        path_mmproj,
        (char *)"-c",
        (char *)context_len_str.c_str(),
    };
    int argc=sizeof(argv)/sizeof(char *);
    
    // Can we process our parameters?
    if (!common_params_parse(argc, argv, params, LLAMA_EXAMPLE_MTMD, NULL)) {
        
        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdParseParams, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());

        return GGML_STATUS_FAILED;
    }

    common_init();

    // Can we create a context object?
    _vctx = new mtmd_cli_context(params);
    if ( _vctx == NULL ) {
        
        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdClientContext, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());
        
        return GGML_STATUS_FAILED;
    }
    mtmd_cli_context *ctx=(mtmd_cli_context *)_vctx;
    
    // Initialize instance members
    _n_predict = params.n_predict < 0 ? INT_MAX : params.n_predict;
    _is_first_msg = true;
    _context.clear();
    
    *is_vision_supported = mtmd_support_vision(ctx->ctx_vision.get());
    *is_audio_supported = mtmd_support_audio(ctx->ctx_vision.get());
    
    LOG_INF("Successfully initialized\n");
    
    return GGML_STATUS_SUCCESS;
}

/**
 * @brief Uninitializes this adapter
 *
 * @return The status of the operation
 */
int lr_mtmd_cli::deinit() {
    
    if ( _vctx ) {
        
        // Cast to required mtmd_cli_context
        mtmd_cli_context *ctx=(mtmd_cli_context *)_vctx;
        delete ctx;
        _vctx=ctx=NULL;
        LOG_INF("Successfully uninitialized\n");
    }
    return GGML_STATUS_SUCCESS;
}


/**
 * @brief Evaluates a chat message
 *
 * @param vmsg pointer to a mtmd_cli_context structure
 * @param add_bos add
 *
 * @return The status of the operation
 */
int lr_mtmd_cli::eval_message(void *vmsg, bool add_bos/* = false*/) {
    
    // Did we get the parameters we need?
    if ( !_vctx || !vmsg ) {
        
        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdParams, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());
        
        return GGML_STATUS_FAILED;
    }
    
    // Cast to required mtmd_cli_context
    mtmd_cli_context *ctx=(mtmd_cli_context *)_vctx;
    
    // Cast to required common_chat_msg
    common_chat_msg *msg=(common_chat_msg *)vmsg;
    
    common_chat_templates_inputs tmpl_inputs;
    tmpl_inputs.messages = {*msg};
    tmpl_inputs.add_generation_prompt = true;
    tmpl_inputs.use_jinja = false; // jinja is buggy here
    auto formatted_chat = common_chat_templates_apply(ctx->tmpls.get(), tmpl_inputs);
    LOG_DBG("formatted_chat.prompt: %s\n", formatted_chat.prompt.c_str());

    mtmd_input_text text;
    text.text          = formatted_chat.prompt.c_str();
    text.add_special   = add_bos;
    text.parse_special = true;

    if (_is_interrupted) {
        lr_mtmd_cli_callback(this, LlamarattiEventResponse,"\n");
        return 0;
    }
    
    mtmd::input_chunks chunks(mtmd_input_chunks_init());
    auto bitmaps_c_ptr = ctx->bitmaps.c_ptr();
    int32_t res = mtmd_tokenize(ctx->ctx_vision.get(),
                                chunks.ptr.get(), // output
                                &text, // text
                                bitmaps_c_ptr.data(),
                                bitmaps_c_ptr.size());
    if (res) {
        
        auto args = std::make_format_args(__func__, res);
        std::string err=std::vformat(gErrMtmdTokenize, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());

        return res;
    }

    ctx->bitmaps.entries.clear();

    llama_pos new_n_past;
    res = mtmd_helper_eval_chunks(ctx->ctx_vision.get(),
                                  ctx->lctx, // lctx
                                  chunks.ptr.get(), // chunks
                                  ctx->n_past, // n_past
                                  0, // seq_id
                                  ctx->n_batch, // n_batch
                                  true, // logits_last
                                  &new_n_past);
    if (res) {
        
        auto args = std::make_format_args(__func__, res);
        std::string err=std::vformat(gErrMtmdEvalPrompt, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());
        
        return res;
    }

    ctx->n_past = new_n_past;

    lr_mtmd_cli_callback(this, LlamarattiEventResponse,"\n");
    
    return GGML_STATUS_SUCCESS;
}

/**
 * @brief Generates a series of responses
 *
 * @param n_predict number of tokens
 *
 * @return The status of the operation
 */
int lr_mtmd_cli::gen_response(int n_predict) {
    
    // Did we get the parameters we need?
    if ( !_vctx ||
         n_predict == 0 ) {
        
        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdParams, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());
        
        return GGML_STATUS_FAILED;
    }
    
    // Cast to required mtmd_cli_context
    mtmd_cli_context *ctx=(mtmd_cli_context *)_vctx;

    llama_tokens generated_tokens;
    for (int i = 0; i < n_predict; i++) {
        if (i > _n_predict || !_is_generating || _is_interrupted) {
            lr_mtmd_cli_callback(this, LlamarattiEventResponse,"\n");
            break;
        }

        llama_token token_id = common_sampler_sample(ctx->smpl, ctx->lctx, -1);
        generated_tokens.push_back(token_id);
        common_sampler_accept(ctx->smpl, token_id, true);

        if (llama_vocab_is_eog(ctx->vocab, token_id) || ctx->check_antiprompt(generated_tokens)) {
            lr_mtmd_cli_callback(this, LlamarattiEventResponse,"\n");
            break; // end of generation
        }
        
        // Have we been asked to stop?
        std::string piece=common_token_to_piece(ctx->lctx, token_id);
        if ( lr_mtmd_cli_callback(this, LlamarattiEventResponse,(char *)piece.c_str()) ) {
            break;
        }

        if (_is_interrupted) {
            lr_mtmd_cli_callback(this, LlamarattiEventResponse,"\n");
            break;
        }

        // Can we evaluate the token?
        common_batch_clear(ctx->batch);
        common_batch_add(ctx->batch, token_id, ctx->n_past++, {0}, true);
        if (llama_decode(ctx->lctx, ctx->batch)) {
            
            auto args = std::make_format_args(__func__);
            std::string err=std::vformat(gErrMtmdDecodeToken, args);
            LOG_ERR("%s\n", err.c_str());
            lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());

            return GGML_STATUS_ABORTED;
        }
    }
    return GGML_STATUS_SUCCESS;
}

/**
 * @brief Evaluates & responds to a prompt
 *
 * Evaluates a prompt and responds via the custom callback
 * Call this from a background thread
 *
 * @return The status of the operation
 */
int lr_mtmd_cli::evaluate_and_respond(char *prompt) {
    
    // Did we get the parameters we need?
    if ( !_vctx ||
         !is_valid_string(prompt) ) {
        
        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdParams, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());

        return GGML_STATUS_FAILED;
    }

    _context += prompt;
    
    _is_interrupted = false;
    _is_generating = true;
    
    common_chat_msg msg;
    msg.role = "user";
    msg.content = _context;
    
    // Can we evaluate this message?
    int ret = eval_message(&msg, _is_first_msg);
    if (ret) {
        _is_generating = false;
        return ret;
    }
    
    // Can we generate a response?
    ret = gen_response(_n_predict);
    _is_generating = false;
    if (ret) {
        return ret;
    }

    // Reset parameters
    _context.clear();
    _is_first_msg = false;
    
    return GGML_STATUS_SUCCESS;
}

/**
 * @brief Returns whether the model text generation is in progress
 *
 * @return Whether the model text generation is in progress
 */
bool lr_mtmd_cli::is_generating() {
    
    return _is_generating;
}

/**
 * @brief Returns whether the model text generation was interrupted
 *
 * @return Whether the model text generation is interrupted
 */
bool lr_mtmd_cli::is_interrupted() {
    
    return _is_interrupted;
}

/**
 * @brief Signal to stop text generation
 *
 */
void lr_mtmd_cli::stop_generating() {
    
    _is_interrupted=true;
}

/**
 * @brief Loads the specified audio or video media into the current context
 *
 * @param media_path the path to the media file to load
 *
 * @return The status of the operation
 */
int lr_mtmd_cli::load_media(char *media_path) {
    
    // Did we get the parameters we need?
    if ( !_vctx ||
         !is_valid_string(media_path) ) {

        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdParams, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());
        
        return GGML_STATUS_FAILED;
    }
    // Cast to required mtmd_cli_context
    mtmd_cli_context *ctx=(mtmd_cli_context *)_vctx;

    // Can we load the media?
    if ( !ctx->load_media(media_path) ) {

        auto args = std::make_format_args(__func__,media_path);
        std::string err=std::vformat(gErrMtmdLoadMedia, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());
        
        return GGML_STATUS_FAILED;
    }
    
    _context += mtmd_default_marker();

    return GGML_STATUS_SUCCESS;
}

/**
 * @brief Clears the current chat history
 *
 * @return The status of the operation
 */
int lr_mtmd_cli::clear_history() {
    
    // Did we get the parameters we need?
    if ( !_vctx ) {

        auto args = std::make_format_args(__func__);
        std::string err=std::vformat(gErrMtmdParams, args);
        LOG_ERR("%s\n", err.c_str());
        lr_mtmd_cli_callback(this, LlamarattiEventStatus,err.c_str());
        
        return GGML_STATUS_FAILED;
    }
    // Cast to required mtmd_cli_context
    mtmd_cli_context *ctx=(mtmd_cli_context *)_vctx;
    
    ctx->n_past=0;
    llama_kv_self_seq_rm(ctx->lctx, 0, 1, -1); // keep BOS
    
    ctx->bitmaps.entries.clear();
    
    LOG_DBG("Successfully cleared history");
    
    return GGML_STATUS_SUCCESS;
}

/**
 * @brief Default callback used if the user doesn't supply one
 *
 * @return The status of the operation
 */
bool default_lr_mtmd_cli_callback(void *vmtmd,
                                  LlamarattiEvent event,
                                  const char *piece) {
    
    if ( !vmtmd ) {
        return false;
    }
    
    lr_mtmd_cli *mtmd=(lr_mtmd_cli *)vmtmd;
    
    switch (event) {
            
        // Status Update
        case LlamarattiEventStatus:
            LOG("Status: %s\n", piece);
            fflush(stdout);
            break;
            
        // Response Update
        case LlamarattiEventResponse:
            LOG("%d: %s\n", (int)event, piece);
            fflush(stdout);
            
        default:
            break;
    }
    
    // Keep executing
    return mtmd->is_interrupted();
}
