# Regex Tool - Full-Featured Regex Utility

A comprehensive regex utility for pattern matching, text processing, and program generation. This tool provides a powerful command-line interface and Python API for advanced regex operations.

## Features

### Core Capabilities
- **Pattern Matching**: Advanced regex pattern matching with caching and optimization
- **File Processing**: Process individual files or entire directories recursively
- **Text Operations**: Search, substitute, split, and extract data from text
- **Multiple Output Formats**: Text, JSON, and CSV output options
- **Predefined Patterns**: Built-in library of common regex patterns
- **Code Generation**: Generate code templates from regex matches
- **Pattern Validation**: Validate regex syntax and analyze pattern structure

### Advanced Features
- **Named Groups**: Extract structured data using named capture groups
- **Regex Flags**: Support for case-insensitive, multiline, and other regex modes
- **Performance Optimization**: Pattern compilation caching for improved performance
- **Error Handling**: Robust error handling with detailed error messages
- **Extensible**: Easy to extend with custom patterns and formatters

## Installation

1. Clone or download the repository
2. Make the script executable:
   ```bash
   chmod +x regex_tool.py
   ```
3. Run directly with Python:
   ```bash
   python3 regex_tool.py --help
   ```

## Quick Start

### Basic Usage

```bash
# Find email addresses in a file
python3 regex_tool.py -p EMAIL -f document.txt

# Search for custom pattern in directory
python3 regex_tool.py -p "def\s+(\w+)" -d /path/to/code --file-pattern "*.py"

# Find pattern in text directly
python3 regex_tool.py -p "\d+" -t "Numbers: 123, 456, 789"

# Use stdin input
echo "test@example.com and admin@test.org" | python3 regex_tool.py -p EMAIL --stdin
```

### Predefined Patterns

List available predefined patterns:
```bash
python3 regex_tool.py --list-patterns
```

Available patterns include:
- `EMAIL`: Email addresses
- `URL`: HTTP/HTTPS URLs
- `IP_ADDRESS`: IPv4 addresses
- `PHONE_US`: US phone numbers
- `CREDIT_CARD`: Credit card numbers
- `DATE_ISO`: ISO format dates (YYYY-MM-DD)
- `TIME_24H`: 24-hour time format
- `HEX_COLOR`: Hexadecimal color codes
- `MAC_ADDRESS`: MAC addresses
- `MARKDOWN_LINK`: Markdown links
- `HTML_TAG`: HTML tags

## Command Line Options

### Pattern and Input Options
```bash
-p, --pattern PATTERN     # Regex pattern or predefined pattern name
-f, --file FILE          # File to search in
-d, --directory DIR      # Directory to search recursively
--file-pattern PATTERN   # Pattern to match filenames (default: all files)
-t, --text TEXT         # Text to search in directly
--stdin                 # Read text from stdin
```

### Operations
```bash
-r, --replace TEXT      # Replacement text for substitution
--substitute           # Perform substitution instead of finding matches
--split               # Split text using pattern
--extract             # Extract structured data using named groups
--validate            # Validate pattern syntax only
--generate-code       # Generate code from matches
```

### Regex Flags
```bash
-i, --ignore-case     # Case-insensitive matching
-m, --multiline       # Multiline mode (^ and $ match line boundaries)
-s, --dotall          # Dot matches newlines
-x, --verbose         # Verbose regex mode (ignore whitespace and comments)
```

### Output Options
```bash
-o, --output FORMAT   # Output format: text, json, csv (default: text)
--output-file FILE    # Save output to file
--count              # Only show match count
--max-matches N      # Maximum number of matches (0 = unlimited)
```

## Examples

### 1. Finding Email Addresses

```bash
# Find emails in a file
python3 regex_tool.py -p EMAIL -f contacts.txt

# Find emails with JSON output
python3 regex_tool.py -p EMAIL -f contacts.txt -o json

# Case-insensitive email search
python3 regex_tool.py -p EMAIL -f contacts.txt -i
```

### 2. Text Substitution

```bash
# Mask email addresses
python3 regex_tool.py -p EMAIL -r "[REDACTED]" -t "Contact: john@example.com" --substitute

# Format phone numbers
python3 regex_tool.py -p "(\d{3})(\d{3})(\d{4})" -r "(\1) \2-\3" -t "5551234567" --substitute

# Convert date formats
python3 regex_tool.py -p "(\d{2})/(\d{2})/(\d{4})" -r "\3-\1-\2" -t "01/15/2024" --substitute
```

### 3. Data Extraction

```bash
# Extract structured data with named groups
python3 regex_tool.py -p "(?P<name>\w+):\s*(?P<value>\d+)" -t "price: 100, quantity: 5" --extract

# Extract function names from Python code
python3 regex_tool.py -p "def\s+(\w+)" -d ./src --file-pattern "*.py" -o json
```

### 4. Directory Processing

```bash
# Find all IP addresses in log files
python3 regex_tool.py -p IP_ADDRESS -d /var/log --file-pattern "*.log"

# Search Python files for class definitions
python3 regex_tool.py -p "class\s+(\w+)" -d ./project --file-pattern "*.py"

# Find TODO comments in source code
python3 regex_tool.py -p "(?i)#\s*todo:?\s*(.*)" -d ./src --file-pattern "*.py"
```

### 5. Advanced Pattern Matching

```bash
# Multiline matching
python3 regex_tool.py -p "^def.*?^$" -f code.py -m -s

# Case-insensitive URL matching
python3 regex_tool.py -p URL -f document.html -i

# Verbose pattern with comments
python3 regex_tool.py -p "(?x) \d+  # Match digits" -t "123 abc 456" -x
```

### 6. Output Formatting

```bash
# JSON output for programmatic processing
python3 regex_tool.py -p EMAIL -f contacts.txt -o json > emails.json

# CSV output for spreadsheet import
python3 regex_tool.py -p PHONE_US -f contacts.txt -o csv > phones.csv

# Count matches only
python3 regex_tool.py -p "\w+" -f document.txt --count
```

### 7. Code Generation

```bash
# Generate code from function matches
python3 regex_tool.py -p "def\s+(\w+)" -f script.py --generate-code > analysis.py

# Generate report from log analysis
python3 regex_tool.py -p "ERROR.*" -d /var/log --generate-code > error_report.py
```

## Python API

You can also use the Regex Tool as a Python library:

```python
from regex_tool import RegexTool, RegexPatterns, RegexFormatter

# Initialize the tool
tool = RegexTool()

# Basic pattern matching
result = tool.find_matches(RegexPatterns.EMAIL, "Contact us at support@example.com")
print(f"Found {len(result.matches)} email addresses")

# Text substitution
masked = tool.substitute(RegexPatterns.EMAIL, "[EMAIL]", "Send to admin@test.com")
print(masked)  # Output: Send to [EMAIL]

# Data extraction with named groups
pattern = r"(?P<name>\w+):\s*(?P<value>\d+)"
data = tool.extract_data(pattern, "price: 100, qty: 50")
print(data)  # [{'name': 'price', 'value': '100'}, {'name': 'qty', 'value': '50'}]

# File processing
results = tool.process_file("data.txt", RegexPatterns.IP_ADDRESS)
for result in results:
    print(f"Line {result.line_number}: {[m.group() for m in result.matches]}")

# Pattern validation
validation = tool.validate_pattern(r"[a-z]+")
if validation['valid']:
    print("Pattern is valid")
else:
    print(f"Pattern error: {validation['error']}")
```

## Advanced Use Cases

### Log Analysis
```bash
# Find error patterns in logs
python3 regex_tool.py -p "ERROR.*" -d /var/log --file-pattern "*.log" -o json

# Extract timestamps and error codes
python3 regex_tool.py -p "(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*ERROR.*(?P<code>\d{3})" -f app.log --extract
```

### Code Analysis
```bash
# Find all imports in Python files
python3 regex_tool.py -p "^(?:from\s+\S+\s+)?import\s+.*" -d ./project --file-pattern "*.py" -m

# Extract function documentation
python3 regex_tool.py -p '"""(.*?)"""' -d ./src --file-pattern "*.py" -s
```

### Data Processing
```bash
# Extract structured data from CSV-like text
python3 regex_tool.py -p "(?P<name>[^,]+),\s*(?P<age>\d+),\s*(?P<email>\S+@\S+)" -f data.txt --extract

# Clean and format phone numbers
python3 regex_tool.py -p "[\(\)\-\.\s]" -r "" -f contacts.txt --substitute
```

### Security Analysis
```bash
# Find potential SQL injection patterns
python3 regex_tool.py -p "(?i)(union|select|insert|update|delete).*" -d ./web --file-pattern "*.php"

# Extract potential credentials
python3 regex_tool.py -p "(?i)(password|key|secret|token)\s*[:=]\s*['\"]?([^'\";\s]+)" -d ./config
```

## Pattern Development Tips

### 1. Start Simple
Begin with basic patterns and gradually add complexity:
```bash
# Start with: \d+
# Then: \d{1,3}
# Finally: \b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b
```

### 2. Use Pattern Validation
Always validate patterns before using them extensively:
```bash
python3 regex_tool.py -p "your_pattern_here" --validate
```

### 3. Test with Sample Data
Use the `--text` option to test patterns quickly:
```bash
python3 regex_tool.py -p "\b\w{3}\b" -t "The cat sat on the mat"
```

### 4. Use Named Groups for Data Extraction
Named groups make extracted data more readable:
```bash
python3 regex_tool.py -p "(?P<protocol>https?)://(?P<domain>[^/]+)" -t "https://example.com" --extract
```

## Performance Tips

1. **Use Specific Patterns**: More specific patterns are faster than broad ones
2. **Leverage Caching**: The tool automatically caches compiled patterns
3. **Limit File Scope**: Use `--file-pattern` to process only relevant files
4. **Use `--max-matches`**: Limit results when you only need a few matches
5. **Consider Output Format**: JSON parsing may be slower for very large results

## Troubleshooting

### Common Issues

1. **"Invalid regex pattern" error**
   - Use `--validate` to check pattern syntax
   - Escape special characters: `\.` instead of `.`

2. **No matches found**
   - Try case-insensitive matching with `-i`
   - Use multiline mode `-m` for multi-line patterns
   - Check if the pattern needs the dotall flag `-s`

3. **File processing errors**
   - Check file permissions and encoding
   - Use `--file-pattern` to filter relevant files

4. **Performance issues**
   - Use more specific patterns
   - Limit search scope with `--max-matches`
   - Consider processing smaller file sets

### Debug Mode
Use the `--verbose` flag for detailed error information:
```bash
python3 regex_tool.py -p "problematic_pattern" -f file.txt --verbose
```

## Contributing

The Regex Tool is designed to be extensible. You can:

1. **Add New Predefined Patterns**: Edit the `RegexPatterns` class
2. **Create Custom Formatters**: Extend the `RegexFormatter` class
3. **Add New Operations**: Extend the `RegexTool` class

## License

This tool is provided as-is for educational and practical use. Feel free to modify and distribute according to your needs.

## Support

For issues, questions, or feature requests, please refer to the source code documentation and examples provided in `examples.py`.