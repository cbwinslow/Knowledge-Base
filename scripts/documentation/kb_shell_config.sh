# Knowledge Base Shell Configuration
# Add this to your ~/.bashrc or ~/.zshrc to enable KB functions

# Knowledge Base Management System
if [[ -f "/home/cbwinslow/Knowledge-Base/scripts/documentation/kb_functions.sh" ]]; then
    # Source the functions
    source "/home/cbwinslow/Knowledge-Base/scripts/documentation/kb_functions.sh"
    
    # Create command alias
    alias kb="/home/cbwinslow/Knowledge-Base/scripts/documentation/kb"
    
    # Auto-completion for kb command
    _kb_cli_complete() {
        local cur prev commands
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        
        commands="init search add remove lookup copy open bookmark bookmarks unbookmark stats update toc help"
        
        if [[ ${COMP_CWORD} -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        fi
    }
    
    complete -F _kb_cli_complete kb
fi

# Knowledge Base prompt integration (optional)
# Uncomment below to add KB status to your prompt
# kb_prompt_info() {
#     if [[ -f "/home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json" ]]; then
#         local doc_count=$(jq '. | length' "/home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json" 2>/dev/null || echo "?")
#         echo "[KB:$doc_count]"
#     fi
# }
# 
# # Add to prompt (example)
# PS1='\u@\h:\w$(kb_prompt_info)\$ '