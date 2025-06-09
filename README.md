# llamaratti
# 🏎️👆🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️

A simple, on-device macOS Silicon M-Series Llama.cpp wrapper & test app for piloting LLM inferencing.

![Screenshot](https://github.com/on-device-ml/llamaratti/blob/main/llamaratti_prompt1.jpg)

## Target Devices

1) Apple Silicon M-series Macs such as M1, M2, M3, M4, and their Pro, Max, and Ultra versions

## Installing

  1) Make sure you have XCode installed
  
  2) Install [Brew for macOS](https://brew.sh)

  3) Install cmake
     ```
    brew install cmake
     ```
  3) Clone Llama.cpp to your projects folder
     ```
     git clone https://github.com/ggml-org/llama.cpp.git
     ```
  4) Build Llama.cpp
     ```
     cd llama.cpp
     mkdir build
     cd build
     cmake ..
     make
     ```
  6) Clone this project to your projects folder
     ```
     git clone https://github.com/on-device-ml/llamaratti.git
     ```
  7) Build my-llama-mtmd in XCode - output will be libmy-llama-mtmd.a
  
  8) Load Llamaratti in XCode
  Ensure the location of the llama.cpp dylibs are correctly specified under Build Settings, so they can be found at runtime:
     ```
     Under LD_RUNPATH_SEARCH_PATHS, Add "@executable_path/../../../../../llama.cpp/build/bin"
     ```

  9) Rebuild & Run
  
  10) Download some LLMs/MMProj files
     
     Examples:<br/>
     [Llama](https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/tree/main)<br/>
     [Mistral](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/tree/main)<br/>
     [Other Llama.cpp supported models](https://github.com/ggml-org/llama.cpp/discussions/5141)<br/>
   
## Test App Features

  - llamaratti: A simple Objective-C App based on llama.cpp that includes:
      
    - Drag/drop interface for querying image & audio files
    - Text chat capabilities via prompt/response windows, allowing you to query the currently loaded LLM
    - Load/selection of supported models/mmproj files:
            - Load from Llama.cpp cache folder - exists if you previously used llama-mtmd-cli to download a model & projector
            - Load from recently used folder
            - Load from user selected folder
            - Remembers the last used LLM & auto-loads it the next time you run
    - Displays multimodal capabilities of the currently loaded model - ex: VISION, AUDIO
    - Button to view GPU usage by launching macOS Activity Monitor
    - Displays the currently selected LLM in the title bar
    - Displays timing for each prompt/response

## Objective-C Wrapper 
  
    - LlamaMultimodalWrapper.m/h - grab this & the my-llama-mtmd if you don't care about anything else
  
## C Wrapper
    - my-llama-mtmd: A small library that provides simplified access to basic llama.cpp capabilities via a C interface. Used by the wrapper.
  
## Performance

  - Refer to [these M-Series numbers](https://github.com/ggml-org/llama.cpp/discussions/4167) from @ggerganov
  - This was developed on a MacBook M4 Pro Max & tested on an entry-level MacBook M1
  - Results thanks to the efficiency of Llama.cpp, the tirelessly optimized models available from the ML Community & Apple Silicon 
  - Loading & initialization of the models is notably slower on the older M-series, such as M1. Inference seems ok
  
## Notes

  1) The GPU button launches the Activity Monitor, then displays the GPU graph
  2) If you get a message when you click this button, its because keystroke automation is needed to display the GPU graph
  3) Alternately, after launching Activity Monitor, you can just select CMD-4 to display the graph


