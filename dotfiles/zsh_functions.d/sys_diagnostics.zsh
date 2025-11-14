
# Zsh function to display top CPU consuming processes
top_cpu() {
  echo "--- Top 20 CPU Consuming Processes ---"
  ps aux --sort=-%cpu | head -n 20
  echo "--------------------------------------"
}
