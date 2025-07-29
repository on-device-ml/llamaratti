
# llamaratti

A macOS Silicon wrapper & demo apps for developers to simplify access to llama.cpp multimodal capabilities.

[![Watch the video](https://img.youtube.com/vi/d83XIHJsXaA/0.jpg)](https://www.youtube.com/watch?v=d83XIHJsXaA)

# Quick Start

⚡️Jump to these sections to get up & running:

1) [Before We Start](#before-we-start)
2) [Building llama](#building-llama)
3) [Building and Running llamaratti](#building-and-running-llamaratti)
4) [Downloading Models](#downloading-models)
5) [Using Models in llamaratti](#using-models-in-llamaratti)

## Before We Start

- llamaratti is a tool for developers creating on-device Apple Silicon apps that use llama.cpp multimodal capabilities. It provides convenience features such as drag/drop/conversion of multimedia files, simple prompt selection, simple changes to model settings, timing of loading/querying and displays simple metrics that can help understand the system impact of models.

- llamaratti uses llama.cpp multimodal libraries that are still **in development**.  **This means this project will be impacted by future updates**.

- llamaratti doesn't support non-multimodal models - there are plenty of great Apps to do this such as LM Studio and others. Support may be introduced in the future.

- What is a GGUF? - GPT-Generated Unified Format is a file format developed by the creators of llama.cpp, designed to store and load large language models (like LLaMA, Mistral, and others) efficiently for use in local inference engines.

- Model Pair - In this project, this term refers to the two models that llama.cpp multimodal requires to perform multimodal inferencing - the model & model projector GGUFs. 

- Known Models - In this project, refers to the model details that are stored in an internal array within the llamaratti wrapper . Generally these are models that we have been testing with, but you can also add new ones as needed to the array.

- Downloading models - llamaratti allows you to load models directly from the llama.cpp cache folder, which means if you've already been using llama command line tools, you won't need to move or re-download them.

- Demo Apps - The Obj-C app generally gets new features first, which may then be migrated to the Swift app

- Back to [Quick Start](#quick-start)


## Modules

1) **llamaratti**                                   - Test app (Obj-C) - uses shared LlamarattiWrapper.h/.mm
2) **llamaratti-swift**                           - Test app (Swift) - uses shared LlamarattiWrapper.h/.mm
3) **lr-mtmd-cli**                                 - C++ interface wrapper library based on llama.cpp multimodal, which is used by LlamarattiWrapper.h/mm


## Features - llamaratti Demo App

- Supports running in sandboxed and non-sandboxed modes
- Provides gauges that
    - Allow configuration of LLM model temperature and context length
    - Provide visibility into system metrics, such as system memory, disk space & physical temperature
    - The physical temperature gauge 
        - appears in non-sandboxed mode only, since it requires deeper access to the O/S
        - only works for Apple devices with a built-in battery
- Drag/drop interface for querying image & audio files
    - Dynamically converts some formats to llama.cpp compatible (heic/webp)
- Text chat capabilities via prompt/response windows, allowing you to query the currently loaded model pair
- Load/select of downloaded model pairs
    - Load from llama.cpp default cache folder - exists if you previously used **llama-mtmd-cli** or other llama tools to download models
    - Load from ~/Downloads folder
    - Load from user selected folder
    - Load from recently used folder
    - Auto-loads the last used model pair when launched. If a problem occurs during inference the model will no longer be auto-loaded.
    - Allows menu selection of recently selected models
    - Launch to model downloads page
    - Ref: [Downloading and Using Models](#downloading-and-using-models)
- Performs a hash check on known models the first time you load a model pair during a session - toggle in shared.h
- If a problem occurs during inference the model is auto-reloaded
- Displays multimodal capabilities of the currently loaded model using icons on the top right side of the screen
- Button to launch macOS Activity Monitor. Press CMD-4 to show the GPU graph
- Displays the currently loaded model & Mac device model in the title bar
- Allows selection of pre-defined prompts and remembers the ones you used previously in NSUserDefaults - toggle in shared.h
- Displays timing for loading/prompt/response
- Allows customizing additional per-model parameters 

## Features - llamaratti-swift Demo App

- Supports running in sandboxed mode
- Drag/drop interface for querying image & audio files
- Text chat capabilities via prompt/response windows, allowing you to query the currently loaded model pair
- Load/select of downloaded model pairs &#129093;
    - Load from llama.cpp default cache folder - exists if you previously used **llama-mtmd-cli**/other llama tools to download models
    - Load from ~/Downloads folder
    - Load from user selected folder
    - Load from recently used folder
    - Auto-loads the last used model pair when launched. If a problem occurs during inference the model will no longer be auto-loaded.
    - Allows menu selection of recently selected models
    - Launch to model downloads page
    - Ref: [Downloading and Using Models](#downloading-and-using-models)
- Performs a hash check on known models the first time you load a model pair during a session - toggle in AppConstants
- If a problem occurs during inference the model is auto-reloaded
- Displays multimodal capabilities of the currently loaded model using icons on the top right side of the screen
- Button to launch macOS Activity Monitor. Press CMD-4 to show the GPU graph
- Displays the currently loaded model & Mac device model in the title bar
- Displays timing for loading/prompt/response


## Supported File Types

<pre>
- Images: jpg, jpeg, heic, png, bmp, gif, webp
- Audio: wav, mp3, flac
- Video: Not supported
</pre>


## Target Devices and O/S

Modules targeted for these **Devices:**<br>
<pre>
 - Apple Silicon M-series Macs such as M1, M2, M3, M4 and their Pro, Max, and Ultra versions
</pre>

...**O/S versions:**<br>
<pre>
- macOS 14 Sonoma
- macOS 15 Sequoia
- macOS Tahoe 25 (25A5295e)
</pre>

## Development and Test Environments

Modules created/tested using these **llama.cpp versions**:<br>
<pre>
- llama.cpp builds: 5760, 5857, 5902, 5970, 5972
</pre>

...**Devices:**<br>
<pre>
- MacBook M4 Max 32Gb
- MacBook M4 16Gb
- MacBook M1 16Gb
</pre>

...**O/S versions:**<br>
<pre>
- macOS 14 Sonoma
- macOS 15 Sequoia
- macOS Tahoe 25 (25A5295e)
</pre>

...**XCode versions:**<br>
<pre>
- XCode 16.4 (16F6)
- XCode 26.0 beta (17A5241e)
</pre>
    
...**Themes:**<br>
<pre>
Developed & tested mainly in dark mode 🌙
</pre>

...**Multimodal Models:**<br>
<pre>
- Gemma 3 12b
- Gemma 3 27b
- Llama 4 Scout 17b
- Mistral 3.1 24b
- Pixtral 12b
- InternVL 2 1b
- InternVL 3 8b
- SmolVLM Instruct
- SmolVLM2 Instruct 256m
- SmolVLM2 Instruct 500m
- SmolVLM2 Instruct 2.2b
- SmolVLM2 Video Instruct 250m
- SmolVLM2 Video Instruct 500m
- Qwen2 VL 2B
- Qwen Omni 2.5 3b
- Qwen Omni 2.5 7b
- Moondream 2
- Ultravox 3.2 1b    
</pre>


## Building llama

1. Make sure you have XCode installed.<br><br>
  
2. Install [Brew for macOS](https://brew.sh)<br><br>
  
3. Install cmake<br>
<pre>
brew install cmake
</pre>
    
4. Create a projects folder ex: MyProjects & clone llama.cpp to the MyProjects folder. We'll assume that llamaratti will be installed in the same folder as the llama.cpp library
<pre>
 mkdir MyProjects
 cd MyProjects 
 git clone https://github.com/ggml-org/llama.cpp.git
 cd llama.cpp
 mkdir build
 cd build
 cmake ..
 make
</pre>
  
5. Back to [Quick Start](#quick-start)


## Building and Running llamaratti

1. Clone the llamaratti project to your MyProjects folder
<pre>
 git clone https://github.com/on-device-ml/llamaratti.git
</pre>
     
2. Load & rebuild **lr-mtmd-cli** in XCode<br>
<pre>
 Output: ./MyProjects/llamaratti/lr-mtmd-cli/Build/Products/Debug/liblr-mtmd-cli.a
</pre>
     
3. Load either the **llamaratti** or **llamaratti-swift** project in XCode & perform these sanity checks before building<br>
    
Sanity Checks: INCLUDE Folders<br><br>
Under XCode build settings, verify the paths to these include folders:
<pre>
Under HEADER_SEARCH_PATHS:<br>
$(PROJECT_DIR)/../../llama.cpp/include
$(PROJECT_DIR)/../../llama.cpp/ggml/include
$(PROJECT_DIR)/../../llama.cpp/tools/mtmd
$(PROJECT_DIR)/../../llama.cpp/common
$(PROJECT_DIR)/../../llama.cpp/vendor
$(PROJECT_DIR)/../lr-mtmd-cli/lr-mtmd-cli
</pre>

Sanity Checks: LIBRARY Folders<br><br>
Under XCode build settings, verify the paths to these library folders:<br>
<pre>
Under LD_RUNPATH_SEARCH_PATHS:<br>
$(PROJECT_DIR)/../../llama.cpp/build/bin<br>

Under LIBRARY_SEARCH_PATHS:<br>
$(PROJECT_DIR)/../lr-mtmd-cli/Build/Products/Debug
$(PROJECT_DIR)/../../llama.cpp/build/bin
$(PROJECT_DIR)/../../llama.cpp/build/common
</pre>

4. Important: If you're switching between llama.cpp versions and having crashes/other issues, try deleting the **Builds** and **DerivedData** folders in the llamaratti projects prior to doing a full rebuild

5. Enabling the SYS TEMP Gauge (llamartti Obj-C)
The SYS TEMP gauge gets its temperature reading from the system battery, which means its supported on M-series Silicon MacBooks.
Enabling this requires removing the sandboxing capability from the app, so it can dig deeper into IO services. You might want to do this if
you need to monitor the temperature impact locally during local development & testing.<br>
Note: Removing sandboxing results in a less secure application & a rejection if you submit to the App Store.
Follow these additional steps to enable this gauge:
<pre>
 1. Open llamaratti in XCode and on the "Signing and Capabilities" tab remove the "App Sandbox" capability.
 2. Clean & Rebuild.
 3. Note: When adding back the "App Sandbox" capability, make sure to set "User Selected File" back to "Read/Write".
 </pre>
 
6. Back to [Quick Start](#quick-start)


## Downloading Models

Since you've already built llama.cpp, we'll use the existing **llama-mtmd-cli** command line tool to download a llama.cpp compatible model pair. For a list of compatible models go to [GGML Multimodal](https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md)
<pre>
1. This tool should exist in ~/MyProjects/llama.cpp/build/bin.<br>
2. If you previously installed llama.cpp with Brew, it should also exist in /opt/homebrew/bin
and be in your PATH. Ideally you've installed only one copy of the latest version of llama.cpp 
from GitHub. Having duplicate copies of llama.cpp's dylibs on your system can cause problems.<br>
3. Be aware that building with different versions of llama.cpp may yield slightly different
results because it is still **in development**.<br>
4. When upgrading/changing the version of llama.cpp, remember to delete the "Builds" 
and "DerivedData" folders in lr-mtmd-cli/llamaratti/llamaratti-swift prior to a full rebuild.<br>
</pre>

 Ex: To download the SmolVLM model:
<pre>
cd ~/MyProjects/llama.cpp/build/bin
./llama-mtmd-cli -hf ggml-org/SmolVLM-500M-Instruct-GGUF
</pre>
    
When the download completes, two .gguf files should exist in your ~/Library/Caches/llama.cpp folder
<pre>
~/Library/Caches/llama.cpp
    ggml-org_SmolVLM-500M-Instruct-GGUF_mmproj-SmolVLM-500M-Instruct-Q8_0.gguf
    ggml-org_SmolVLM-500M-Instruct-GGUF_SmolVLM-500M-Instruct-Q8_0.gguf
</pre>


## Using Models in llamaratti

The llamaratti Obj-C app uses a known models array in the wrapper to validate the files being loaded. This array is initialized in the initArrays() method. You can add new models to this array as needed:

<pre>
1. Select the ▲ button in the bottom center of the screen to load a model pair.<br>
2. Select the first entry under "Load From Folder..." which is where llama.cpp tools
cache their models.<br>
3. Hold down the CMD key and select both the Model and the MMProj GGUF files.<br>
4. If the selected model pair is known, a SHA256 hash check is done on both GGUF.<br>
files. This check is done only once per session and can be toggled in Shared.h.<br>
5. Once the model pair loads successfully, it'll be saved in preferences and will appear 
in the recents menu.<br>
6. The last used model is generally auto-loaded when you run the app, unless it previously
had problems/errors during inference.<br>
</pre>
  
![Screenshot](https://github.com/on-device-ml/llamaratti/blob/main/lr-load-model-menu.jpg)
  
In the llamaratti Swift app:

<pre>
1. Select the ▲ button in the bottom center of the screen to load a model pair.<br>
2. Select the first entry under "Load From Folder..." which is where llama.cpp tools cache
their models.<br>
3. Hold down the CMD key and select both the Model and the MMProj GGUF files.<br>
4. If the selected model pair is known, a SHA256 hash check is done on both GGUF files. <br>
This check is done only once per session and can be toggled in AppConstants.<br>
5. Once the model pair loads successfully, it'll be saved in preferences and will appear in
the recents menu.<br>
6. The last used model is generally auto-loaded when you run the app, unless it previously
had problems/errors during inference.<br>
</pre>

Back to [Quick Start](#quick-start)


## Resetting User Defaults

llamaratti stores info about recently loaded model pairs in User Defaults. Use one of these options to reset these defaults:<br>
<pre>
1. In the llamaratti app, select the ▲ button and select the "Clear Recents..." option<br>
2. Re-run llamaratti after uncommenting [self resetPrefs] in viewDidLoad()<br>
3. defaults delete "com.your-company.app" # substitute with your App ID<br>
</pre>
    
    
## Known Issues/Observations

These are some known issues:
<pre>
1. Some models may emit tofu or repeated garbled output. For Gemma specifically this 
occurred when there were duplicate copies of llama.cpp on the system. Ex: Homebrew and 
Github builds. The versions between these two sources can differ slightly.<br>
2. Some models may be too large to load & use on your device. The load may hang, or you
may receive an "ERROR: Unable to evaluate prompt. Result=...". In this case try lowering the
context length value in the CTX LEN gauge (llamaratti).<br>
3. After dragging an image into the response window, the image does not refresh when the
window is resized (llamaratti).<br>
4. Some HEIC images don't appear to convert properly when dragged into the response 
view.
</pre>

## Performance

Refer to [these M-Series numbers](https://github.com/ggml-org/llama.cpp/discussions/4167) from @ggerganov & ggml team

Note: The SHA256 check on models can slow the initial load time of models. This can be toggled in shared.h (Obj-C) or AppConstants (Swift)

## Final App Considerations for Builders

In your final product:
<pre>
1. Add "App Sandbox" capabilities to enable sandboxing in your application<br>
2. Add "Hardened Runtime" capabilities - you may need to "Disable Library Validation" for
some modules<br>
3. Add validation/content/bounds checks to inputs such as the Prompts and Files loaded
into the app<br>
4. Consider how the app remembers user entered prompts between sessions and how they
can be secured/cleared<br>
5. When models have problems loading on the current hardware, use methods to prevent
them from auto-loading in future<br>
6. Consider a content delivery network for model distribution<br>
</pre>


## Additional References

- [llama.cpp Main](https://github.com/ggml-org/llama.cpp)
- [llama.cpp Multimodal](https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md)
- [llava : introduce libmtmd](https://github.com/ggml-org/llama.cpp/pull/12849)
- [HuggingFace - Model Deployment Considerations](https://huggingface.co/learn/computer-vision-course/en/unit9/model_deployment)
- [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)


## Credits

Based on the llama.cpp multimodal library by @ggerganov and the ggml team.

Many thanks to the llama.cpp team, the ML community, HuggingFace & the individuals @ Apple who inspired this project 🤗🥇

## Feedback and Contributions

Feedback & suggestions are welcome! Please, feel free to [get in touch](https://github.com/on-device-ml/llamaratti/issues/new).
