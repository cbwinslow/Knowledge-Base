# ==============================================================================
# FILENAME: function_memory_tools.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function Library
#
# PURPOSE:
#   Provides a set of convenience functions for interacting with the Qwen
#   memory management system.
#
# SUMMARY:
#   This script acts as an interface to a separate memory manager script,
#   providing simplified commands for logging tasks, saving conversations,
#   searching memories, checking memory status, listing recent activities,
#   and coordinating with other agents.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: memory_tools
#
# DESCRIPTION:
#   This is the primary entry point for interacting with the Qwen memory
#   manager. It acts as a wrapper, forwarding all arguments to the underlying
#   memory_manager.sh script.
#
# USAGE:
#   memory_tools <command> [args...]
#
# PARAMETERS:
#   $@: All arguments are passed directly to the memory_manager.sh script.
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   The output of the memory_manager.sh script.
#
# ==============================================================================
memory_tools() {
    # Define the path to the memory manager script.
    local memory_manager="$HOME/.qwen/bin/memory_manager.sh"
    
    # Check if the memory manager script exists.
    if [[ ! -f "$memory_manager" ]]; then
        # If the script is not found, print an error message and return.
        echo "Error: Memory manager script not found at $memory_manager"
        return 1
    fi
    
    # Execute the memory manager script, passing all arguments to it.
    "$memory_manager" "$@"
}

# ==============================================================================
# FUNCTION: log_current_task
#
# DESCRIPTION:
#   A convenience function to log the current task with its description,
#   solution, and optional status to the memory system.
#
# USAGE:
#   log_current_task "<task_description>" "<solution_description>" [status]
#
# PARAMETERS:
#   $1 (task_description): A brief description of the task.
#   $2 (solution_description): A detailed description of the solution implemented.
#   $3 (status): Optional. The status of the task (default: "completed").
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   The output of the memory_manager.sh script's log_task command.
#
# ==============================================================================
log_current_task() {
    # Assign the first argument to task_desc.
    local task_desc="$1"
    # Assign the second argument to solution_desc.
    local solution_desc="$2"
    # Assign the third argument to task_status, defaulting to "completed" if not provided.
    local task_status="${3:-completed}"
    
    # Check if required arguments are provided.
    if [[ -z "$task_desc" ]] || [[ -z "$solution_desc" ]]; then
        # If not, print usage and return.
        echo "Usage: log_current_task \"<task_description>\" \"<solution_description>\" [status]"
        return 1
    fi
    
    # Execute the memory manager script to log the task.
    "$HOME/.qwen/bin/memory_manager.sh" log_task "$task_desc" "$solution_desc" "$task_status"
}

# ==============================================================================
# FUNCTION: save_current_conversation
#
# DESCRIPTION:
#   A convenience function to save the current conversation with a title and
#   optional content to the memory system.
#
# USAGE:
#   save_current_conversation "<title>" ["content"]
#
# PARAMETERS:
#   $1 (title): The title of the conversation.
#   $2 (content): Optional. The content of the conversation (default: current date).
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   The output of the memory_manager.sh script's save_conversation command.
#
# ==============================================================================
save_current_conversation() {
    # Assign the first argument to title.
    local title="$1"
    # Assign the second argument to content, defaulting to a date string if not provided.
    local content="$2"
    
    # Check if the title is provided.
    if [[ -z "$title" ]]; then
        # If not, print usage and return.
        echo "Usage: save_current_conversation \"<title>\" [\"content\"]"
        return 1
    fi
    
    # Execute the memory manager script to save the conversation.
    "$HOME/.qwen/bin/memory_manager.sh" save_conversation "$title" "${content:-$(date): Conversation log}"
}

# ==============================================================================
# FUNCTION: search_memories
#
# DESCRIPTION:
#   A convenience function to search through stored memories.
#
# USAGE:
#   search_memories "<query>" [directory]
#
# PARAMETERS:
#   $1 (query): The search query.
#   $2 (directory): Optional. The directory to search within.
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   The search results from the memory_manager.sh script.
#
# ==============================================================================
search_memories() {
    # Assign the first argument to query.
    local query="$1"
    # Assign the second argument to dir.
    local dir="$2"
    
    # Check if the query is provided.
    if [[ -z "$query" ]]; then
        # If not, print usage and return.
        echo "Usage: search_memories \"<query>\" [directory]"
        return 1
    fi
    
    # Execute the memory manager script to perform the search.
    "$HOME/.qwen/bin/memory_manager.sh" search "$query" "$dir"
}

# ==============================================================================
# FUNCTION: memory_status
#
# DESCRIPTION:
#   A convenience function to check the status of the memory system.
#
# USAGE:
#   memory_status
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   The status information from the memory_manager.sh script.
#
# ==============================================================================
memory_status() {
    # Execute the memory manager script to get the status.
    "$HOME/.qwen/bin/memory_manager.sh" status
}

# ==============================================================================
# FUNCTION: list_recent_conversations
#
# DESCRIPTION:
#   A convenience function to list recent conversations from the memory system.
#
# USAGE:
#   list_recent_conversations [count]
#
# PARAMETERS:
#   $1 (count): Optional. The number of recent conversations to list (default: 5).
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   A list of recent conversations from the memory_manager.sh script.
#
# ==============================================================================
list_recent_conversations() {
    # Assign the first argument to count, defaulting to 5 if not provided.
    local count="${1:-5}"
    # Execute the memory manager script to list recent conversations.
    "$HOME/.qwen/bin/memory_manager.sh" list_conversations "$count"
}

# ==============================================================================
# FUNCTION: list_recent_tasks
#
# DESCRIPTION:
#   A convenience function to list recent tasks from the memory system.
#
# USAGE:
#   list_recent_tasks [count]
#
# PARAMETERS:
#   $1 (count): Optional. The number of recent tasks to list (default: 5).
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   A list of recent tasks from the memory_manager.sh script.
#
# ==============================================================================
list_recent_tasks() {
    # Assign the first argument to count, defaulting to 5 if not provided.
    local count="${1:-5}"
    # Execute the memory manager script to list recent tasks.
    "$HOME/.qwen/bin/memory_manager.sh" list_tasks "$count"
}

# ==============================================================================
# FUNCTION: coordinate_with_agents
#
# DESCRIPTION:
#   A convenience function to coordinate with other agents or delegate tasks
#   within the memory system.
#
# USAGE:
#   coordinate_with_agents <operation> <target> [agent]
#
# PARAMETERS:
#   $1 (operation): The operation to perform (e.g., sort_memories, cleanup_memories).
#   $2 (target): The target of the operation.
#   $3 (agent): Optional. The agent to coordinate with (default: "current").
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   The output of the memory_manager.sh script's coordinate command.
#
# ==============================================================================
coordinate_with_agents() {
    # Assign the first argument to operation.
    local operation="$1"
    # Assign the second argument to target.
    local target="$2"
    # Assign the third argument to agent, defaulting to "current" if not provided.
    local agent="${3:-current}"
    
    # Check if required arguments are provided.
    if [[ -z "$operation" ]] || [[ -z "$target" ]]; then
        # If not, print usage and return.
        echo "Usage: coordinate_with_agents <operation> <target> [agent]"
        echo "  Operations: sort_memories, cleanup_memories, organize_memories, validate_memories"
        return 1
    fi
    
    # Execute the memory manager script to coordinate with agents.
    "$HOME/.qwen/bin/memory_manager.sh" coordinate "$operation" "$target" "$agent"
}

# ==============================================================================
# FUNCTION: check_coordination_locks
#
# DESCRIPTION:
#   A convenience function to check for system locks or coordination conflicts.
#
# USAGE:
#   check_coordination_locks <operation>
#
# PARAMETERS:
#   $1 (operation): The operation to check for locks.
#
# INPUTS:
#   None directly, relies on the memory_manager.sh script.
#
# OUTPUTS:
#   The lock status from the memory_manager.sh script.
#
# ==============================================================================
check_coordination_locks() {
    # Assign the first argument to operation.
    local operation="$1"
    # Execute the memory manager script to check for coordination locks.
    "$HOME/.qwen/bin/memory_manager.sh" check_coordination_locks "$operation"
}
