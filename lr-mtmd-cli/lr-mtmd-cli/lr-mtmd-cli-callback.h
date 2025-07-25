/**
 *
 * @file lr-mtmd-cli-callback.h
 *
 * @brief Defines details of the status callback
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#ifndef LR_MTMD_CLI_CALLBACK_H
#define LR_MTMD_CLI_CALLBACK_H

#include <stdbool.h>

// Event types used by the Llamaratti wrapper selector/callback
typedef enum {
    
    // Status update
    LlamarattiEventStatus=0,
    
    // Piece of generated text
    LlamarattiEventResponse=1,
    
    // Add more as needed...
    
} LlamarattiEvent;

extern bool (*lr_mtmd_cli_callback)(void *,
                                    LlamarattiEvent,
                                    const char *);

#endif  // LR_MTMD_CLI_CALLBACK_H
