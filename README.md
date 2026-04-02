**Cross-platform Linux support** - Works on Termux (Android), Kali Linux, Ubuntu, Debian, Arch, and all major Linux distributions.

AutoWebSec - Automated Web Security Scanner

A bash automation script that combines Feroxbuster for directory/file discovery and SQLMap for SQL injection vulnerability testing on discovered URLs.

Features:
• Automatic directory brute-forcing with common web extensions (php, aspx, jsp, do, action)
• Supports both GET and POST methods
• Random user-agent rotation to avoid blocking
• Extracts discovered URLs and feeds them directly to SQLMap
• Automatic SQLMap scan with optimized settings (level 3, risk 2)
• Organized logging with timestamps
• Auto-detects SecLists wordlist location

Requirements:
• Feroxbuster installed
• SQLMap installed
• SecLists wordlist (raft-medium-directories.txt)

Usage:
1. Run install.sh to download required wordlists
2. Execute the script: ./script.sh
3. Enter target URL when prompted
4. Results saved in /storage/emulated/0/x/result/

Output:
• Feroxbuster raw output with timestamps
• Extracted URLs list
• SQLMap scan results in separate directory

Note: For authorized testing only. Use only on systems you own or have permission to test.
