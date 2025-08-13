
# llamaratti

A macOS Silicon wrapper & demo apps for developers to simplify access to llama.cpp multimodal capabilities.

![apple-intelligence](https://github.com/on-device-ml/llamaratti/blob/main/lr-load-model-menu.jpg)

[Watch the video](https://www.youtube.com/watch?v=d83XIHJsXaA)

# Quick Start

⚡️ To get started, assuming a ~/MyProjects project folder:

<pre>
1) Clone llama.cpp to ~/MyProjects & build

2) Download multimodal models:
- Ex: ~/MyProjects/llama.cpp/build/bin/llama-mtmd-cli -hf ggml-org/SmolVLM-500M-Instruct-GGUF. 
- Two gguf models will be saved to llama caches folder: ~/Library/Caches/llama.cpp.

3) Clone llamaratti to ~/MyProjects, then use XCode to build:
- ~/MyProjects/llamaratti/lr-mtmd-cli
- ~/MyProjects/llamaratti/llamaratti

4) Run llamaratti, select ⏶ & select .../Library/Caches/llama.cpp

5) Hold ⌘ and select the 2 downloaded ..gguf models

5) Drag an image into the top response window & ask a question about the image, then select ⏵ or ⌘-Return.
</pre>

# Full Steps

🐢 Jump to these sections to get up & running:

1) [Before We Start](#before-we-start)

2) [Building llama](#building-llama)

3) [Building and Running llamaratti](#building-and-running-llamaratti)

4) [Downloading Models](#downloading-models)

5) [Using Models in llamaratti](#using-models-in-llamaratti)

## Before We Start

- llamaratti uses llama.cpp multimodal libraries that are still **in development**.  **This means this project will be impacted by future updates**.

- llamaratti is a playground/tool for developers creating on-device Apple Silicon apps that use llama.cpp's multimodal capabilities. Provides features such as drag/drop/conversion of multimedia files, simple prompt selection, simple changes to model settings, timing of loading/querying and simple metrics that can help visualize the system impact of models.

- Currently supports multimodal models only. If you're looking for text inference, there are plenty of great Apps to do this, such as LM Studio.

- What is a model GGUF? GPT-Generated Unified Format is a file format developed by the creators of llama.cpp, designed to store and load large language models efficiently for use in local inference engines.

- What is an mmproj GGUF? A multimedia projector is a type of model designed to transform multimodal features into a format that can be digested by the model GGUF.

- Model Pair - In this project, this term refers to the two models that llama.cpp multimodal requires to perform multimodal inferencing - the model & multimodal projector GGUFs. 

- Known Models - In this project, refers to the models that have been tested and are stored in an internal array within the wrapper. This array helps llamaratti use and configure the models automatically. You can also add to/modify this array as needed.

- Downloading models - llamaratti allows you to load models directly from the llama.cpp cache folder, which means if you've already been using llama command line tools, you won't need to move or re-download them.

- Demo Apps - The Objective-C app normally gets new features first, which can then be migrated to the Swift app. The Objective-C app is a good place to start.

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
- Load/select of downloaded model pairs:
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
- macOS Sonoma 14
- macOS Sequoia 14
- macOS Tahoe 26+
</pre>

## Development and Test Environments

Modules created/tested using these **llama.cpp versions**:<br>
<pre>
- llama.cpp builds: 5760, 5857, 5902, 5970, 5972, 6000, 6150
</pre>

...**Devices:**<br>
<pre>
- MacBook M4 Max 32Gb
- MacBook M4 16Gb
- MacBook M1 16Gb
</pre>

...**O/S versions:**<br>
<pre>
- macOS Sonoma 14 
- macOS Sequoia 15 
- macOS Tahoe 26 (25A5295e) Beta 2
- macOS Tahoe 26 (25A5316i) Beta 4
- macOS Tahoe 26 (25A5338b) Beta 6
</pre>

...**XCode versions:**<br>
<pre>
- XCode 16.4 (16F6)
- XCode 26 beta (17A5241e) Beta 1
- XCode 26 beta (17A5285i) Beta 4
- XCode 26 beta (17A5295f) Beta 5
</pre>
    
...**Themes:**<br>
<pre>
Developed & tested mainly in dark mode 🌙
</pre>

...**Multimodal Models:**<br>
<pre>
- Gemma 3 12B
- Gemma 3 27B
- Llama 4 Scout 17B
- Mistral 3.1 24B
- Pixtral 12B
- InternVL 2 1B
- InternVL 3 8B
- SmolVLM Instruct
- SmolVLM2 Instruct 256M
- SmolVLM2 Instruct 500M
- SmolVLM2 Instruct 2.2B
- SmolVLM2 Video Instruct 250M
- SmolVLM2 Video Instruct 500M
- Qwen2 VL 2B
- Qwen Omni 2.5 3B
- Qwen Omni 2.5 7B
- MobileVLM 3B
- Llava v1.5 7B
- Llava 1.6 Mistral 7B
- MiniCPM v2.6
- Moondream 2
- Ultravox 3.2 1B
- Voxtral Mini 3B
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

4. Important: If you're switching between llama.cpp versions and having crashes/other issues, try deleting the **Builds** and **DerivedData** folders from both the llamaratti and lr-mtmd-cli projects prior to performing a full rebuild

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

Llamaratti uses a "known models" array in the wrapper to validate the files being loaded. This array is initialized in the initArrays() method. You can add new models to this array as needed:

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
1. Some models might emit "tofu" or garbled output. This can happen for various reasons, 
including having duplicate copies of llama.cpp on the system. Ex: Homebrew & Github builds, 
custom model parameters, beta versions of macOS & lack of system resources. Using a 
Github installed version of llama.cpp is recommended, since there are still many changes 
happening within llama.cpp multimodal.<br>

2. If you modify parameters in llamaratti and then receive an "ERROR: Unable to parse 
parameters", this is likely due to a parameter thats incompatible with the model or llama. 
Clear the parameters and try again.<br>

3. Some models may be too large to load & use on your device. The load may hang, or you
may receive an "ERROR: Unable to evaluate prompt. Result=...". In this case try lowering the
context length value in the CTX LEN gauge (llamaratti).<br>

4. After dragging an image into the response window, the image does not refresh when the
window is resized (llamaratti).<br>

5. Some .heic images don't appear to convert properly when dragged into the response 
view.<br>

6. When updating the version of llama.cpp be sure to fully rebuild both lr-mtmd-cli & llamaratti
or llamaratti-swift to avoid unpredictable behavior.<br>
</pre>

## Performance

Refer to [these M-Series numbers](https://github.com/ggml-org/llama.cpp/discussions/4167) from @ggerganov & ggml team

Note: The SHA256 check on models can slow the initial load time of models. This can be toggled in shared.h 
(Obj-C) or AppConstants (Swift)

## Final Considerations for Developers

In your final product:
<pre>
1. Add "App Sandbox" capabilities to enable sandboxing in your application<br>
2. Add "Hardened Runtime" capabilities - you may need to "Disable Library Validation" for
some modules<br>
3. Add validation/content/bounds checks to inputs and outputs such as the Prompts and Files 
loaded into the app<br>
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
- [Trend Micro State of AI Security Report 1H 2025](https://www.trendmicro.com/vinfo/us/security/news/threat-landscape/trend-micro-state-of-ai-security-report-1h-2025)

## Credits

Based on the llama.cpp multimodal library by @ggerganov and the ggml team.

Many thanks to the llama.cpp team, the ML community, HuggingFace & the folks @ Apple who inspired this project 🤗🥇

## Feedback and Contributions

Feedback & suggestions are welcome! Please, feel free to [get in touch](https://github.com/on-device-ml/llamaratti/issues/new).
