#for_settings_up 10101010

# SQLMap Feroxbuster Automation Script
# Usage: ./script.sh

# Create log directory
LOG_DIR="/storage/emulated/0/x/result"
mkdir -p "$LOG_DIR"

# Timestamp for log files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check for wordlist in both possible locations
WORDLIST1="SecLists/Discovery/Web-Content/raft-medium-directories.txt"
WORDLIST2="$HOME/wordlists/SecLists/Discovery/Web-Content/raft-medium-directories.txt"

# Determine which wordlist exists
if [ -f "$WORDLIST1" ]; then
    WORDLIST="$WORDLIST1"
    echo "[+] Using wordlist: $WORDLIST1 (existing installation)"
elif [ -f "$WORDLIST2" ]; then
    WORDLIST="$WORDLIST2"
    echo "[+] Using wordlist: $WORDLIST2 (install.sh installation)"
else
    echo "[-] Wordlist not found in any location!"
    echo "    Please run install.sh first to download the wordlist"
    exit 1
fi

# Get target URL
echo "Pls input the url:"
read TARGET_URL

# Validate URL input
if [ -z "$TARGET_URL" ]; then
    echo "Error: No URL provided"
    exit 1
fi

echo "[+] Target URL: $TARGET_URL"
echo "[+] Starting feroxbuster scan..."

# Run feroxbuster
feroxbuster -u "$TARGET_URL" \
    -w "$WORDLIST" \
    -x php,aspx,jsp,do,action \
    -m GET,POST \
    --random-agent \
    --threads 30 \
    --timeout 5 \
    --output "$LOG_DIR/ferox_raw_urls_$TIMESTAMP.txt"

# Check if feroxbuster found any URLs
if [ ! -s "$LOG_DIR/ferox_raw_urls_$TIMESTAMP.txt" ]; then
    echo "[-] No URLs found by feroxbuster"
    exit 1
fi

echo "[+] Feroxbuster completed. Found $(wc -l < "$LOG_DIR/ferox_raw_urls_$TIMESTAMP.txt") URLs"

# Extract only URLs from feroxbuster output
grep -oP 'http[s]?://[^\s]+' "$LOG_DIR/ferox_raw_urls_$TIMESTAMP.txt" > "$LOG_DIR/urls_only_$TIMESTAMP.txt"

# Check if SQLmap directory exists
if [ -d "$HOME/tools/sqlmap" ]; then
    SQLMAP_PATH="$HOME/tools/sqlmap"
elif [ -d "sqlmap" ]; then
    SQLMAP_PATH="sqlmap"
else
    echo "Error: SQLmap not found"
    exit 1
fi

echo "[+] Starting SQLMap scan on discovered URLs..."

# Run SQLMap
cd "$SQLMAP_PATH"
python sqlmap.py -m "$LOG_DIR/urls_only_$TIMESTAMP.txt" \
    --batch \
    --random-agent \
    --threads=10 \
    --level=3 \
    --risk=2 \
    --output-dir="$LOG_DIR/sqlmap_output_$TIMESTAMP"
cd

echo "[+] SQLMap scan completed"
echo "[+] All logs saved to: $LOG_DIR"
ls -la "$LOG_DIR"