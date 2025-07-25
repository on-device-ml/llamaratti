/**
 * @file lr-mtmd-cli.h
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

#ifndef LR_MTMD_CLI_H
#define LR_MTMD_CLI_H

#include <stdbool.h>
#include <string>
#include "lr-mtmd-cli-callback.h"

/**
* @class lr_mtmd_cli
*
* @brief Llamaratti class wrapper for llama.cpp
*
*/
class lr_mtmd_cli {

    void *_vctx;
    
    bool _is_generating;
    bool _is_interrupted;
    bool _is_first_msg;
    
    int  _n_predict;
    std::string _context;
    
    int eval_message(void *vmsg, bool add_bos = false);
    
    int gen_response(int n_predict);

public:
    
    lr_mtmd_cli();
    
    ~lr_mtmd_cli();

    int init( char *path_model,
              char *path_mmproj,
              bool *is_vision_supported,
              bool *is_audio_supported,
              uint32_t context_len,
              float temp,
              uint32_t seed,
              bool (*user_callback)(void *, LlamarattiEvent, const char *));
    
    int deinit();
    
    int evaluate_and_respond(char *prompt);
    
    int load_media(char *media_path);
    
    bool is_generating();
    
    bool is_interrupted();
    
    void stop_generating();
    
    int clear_history();
    
};

#endif  // LR_MTMD_CLI_H
