# llamaratti
# 🏎️👆🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️🏎️

A simple, on-device macOS Silicon M-Series Llama.cpp wrapper & test app for piloting LLM inferencing.

## Target Devices

1) Apple Silicon M-series Macs such as M1, M2, M3, M4, and their Pro, Max, and Ultra versions

## Installing

  1) Install [Brew for macOS](https://brew.sh)

  2) Install Llama.cpp library
     ```
     brew install llama.cpp
     ```
  3) Clone the project
     ```
     git clone https://github.com/on-device-ml/llamaratti.git
     ```
  4) Compile & run in XCode!

## Test App

  - This simple App allows selection/loading/test inference of various LLMs supported by Llama.cpp
  - The app uses the wrapper (LCppWrapper.m/h) to perform its tasks - so grab this if you don't care about anything else
  - Other basic App functions:
      - Displays the currently selected LLM at the top of the screen
      - Remembers the last used LLM. Auto-initializes it the next time you run
      - A "Prompt" and "Response" window allowing you to query the currently loaded LLM along with time taken
      - Loads and inferences the LLM on a background thread (NSOperationQueue)
      - A GPU button that launches macOS Activity Monitor with GPU graph - requires macOS accessibility authorization
      - A "Get New" button that launches to a web page where you can download LLMs

## Wrapper

  - A very simple Objective-C wrapper for Llama.cpp that provides for basic LLM use
  - Grab these files (LCppWrapper.m/h) if you don't care about anything else
  - Refer to the Test App that shows you how to use the wrapper

## Performance

  - Refer to [these M-Series numbers](https://github.com/ggml-org/llama.cpp/discussions/4167) from @ggerganov
  - This was developed on a MacBook M4 Pro Max & tested on an entry-level MacBook M1
  - Results thanks to the efficiency of Llama.cpp, Apple Silicon & the tirelessly optimized models available from the ML Community
  - Loading & initialization of the models is notably slower on the older M-series, such as M1. Inference seems ok
  
## Notes

  1) The GPU button launches the Activity Monitor, then displays the GPU graph
  2) If you get a message when you click this button, its because keystroke automation is needed to display the GPU graph
  3) Alternately, after launching Activity Monitor, you can just select CMD-4 to display the graph


