#!/usr/bin/env python3
"""
Examples and Test Cases for the Regex Tool
Demonstrates various use cases and capabilities of the regex tool.
"""

import os
import sys
import tempfile
from regex_tool import RegexTool, RegexPatterns, RegexFormatter

def create_sample_files():
    """Create sample files for testing."""
    # Create temporary directory
    temp_dir = tempfile.mkdtemp(prefix="regex_examples_")
    
    # Sample log file
    log_content = """
2024-01-15 10:30:45 INFO: User john.doe@example.com logged in from 192.168.1.100
2024-01-15 10:31:12 ERROR: Failed login attempt for admin@test.com from 10.0.0.5
2024-01-15 10:32:00 WARN: High CPU usage detected on server-01
2024-01-15 10:33:15 INFO: User alice.smith@company.org accessed /api/users
2024-01-15 10:34:22 ERROR: Database connection timeout for user bob@domain.net
2024-01-15 10:35:30 INFO: Payment processed: $1,250.99 for order #12345
    """.strip()
    
    log_file = os.path.join(temp_dir, "server.log")
    with open(log_file, 'w') as f:
        f.write(log_content)
    
    # Sample data file
    data_content = """
Name: John Smith, Age: 30, Phone: (555) 123-4567, Email: john@example.com
Name: Jane Doe, Age: 25, Phone: 555.987.6543, Email: jane.doe@test.org
Name: Bob Wilson, Age: 45, Phone: +1-555-111-2222, Email: bob.wilson@company.net
Name: Alice Brown, Age: 35, Phone: (555) 999-8888, Email: alice@domain.com
    """.strip()
    
    data_file = os.path.join(temp_dir, "contacts.txt")
    with open(data_file, 'w') as f:
        f.write(data_content)
    
    # Sample code file
    code_content = """
class UserManager:
    def __init__(self):
        self.users = []
    
    def add_user(self, name, email):
        user = User(name, email)
        self.users.append(user)
        return user
    
    def find_user(self, email):
        for user in self.users:
            if user.email == email:
                return user
        return None

class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
        self.created_at = datetime.now()
    
    def __str__(self):
        return f"User(name='{self.name}', email='{self.email}')"
    """.strip()
    
    code_file = os.path.join(temp_dir, "user_manager.py")
    with open(code_file, 'w') as f:
        f.write(code_content)
    
    return temp_dir, {
        'log': log_file,
        'data': data_file,
        'code': code_file
    }

def example_basic_pattern_matching():
    """Example 1: Basic pattern matching."""
    print("=" * 60)
    print("EXAMPLE 1: Basic Pattern Matching")
    print("=" * 60)
    
    tool = RegexTool()
    
    # Test text
    text = "Contact us at support@example.com or sales@company.org for assistance."
    
    # Find email addresses
    result = tool.find_matches(RegexPatterns.EMAIL, text)
    
    print(f"Text: {text}")
    print(f"Pattern: {RegexPatterns.EMAIL}")
    print(f"Matches found: {len(result.matches)}")
    
    for i, match in enumerate(result.matches):
        print(f"  Match {i+1}: '{match.group()}' at position {match.start()}-{match.end()}")
    
    print()

def example_predefined_patterns():
    """Example 2: Using predefined patterns."""
    print("=" * 60)
    print("EXAMPLE 2: Predefined Patterns")
    print("=" * 60)
    
    tool = RegexTool()
    
    test_text = """
    Visit our website at https://example.com or http://test.org
    Call us at (555) 123-4567 or +1-800-555-0199
    Server IP: 192.168.1.100, Database IP: 10.0.0.5
    Meeting scheduled for 2024-01-15 at 14:30:00
    Color scheme: #FF5733, #33FF57, #3357FF
    MAC Address: 00:1B:44:11:3A:B7
    """
    
    patterns_to_test = [
        ('URL', RegexPatterns.URL),
        ('PHONE_US', RegexPatterns.PHONE_US),
        ('IP_ADDRESS', RegexPatterns.IP_ADDRESS),
        ('DATE_ISO', RegexPatterns.DATE_ISO),
        ('TIME_24H', RegexPatterns.TIME_24H),
        ('HEX_COLOR', RegexPatterns.HEX_COLOR),
        ('MAC_ADDRESS', RegexPatterns.MAC_ADDRESS)
    ]
    
    for pattern_name, pattern in patterns_to_test:
        result = tool.find_matches(pattern, test_text)
        print(f"{pattern_name}: {len(result.matches)} matches")
        for match in result.matches:
            print(f"  - {match.group()}")
        print()

def example_file_processing():
    """Example 3: Processing files."""
    print("=" * 60)
    print("EXAMPLE 3: File Processing")
    print("=" * 60)
    
    temp_dir, files = create_sample_files()
    tool = RegexTool()
    
    try:
        # Process log file for email addresses
        print("Processing log file for email addresses:")
        results = tool.process_file(files['log'], RegexPatterns.EMAIL)
        
        for result in results:
            print(f"  File: {result.file_path}, Line: {result.line_number}")
            for match in result.matches:
                print(f"    Found: {match.group()}")
        
        print("\nProcessing log file for IP addresses:")
        results = tool.process_file(files['log'], RegexPatterns.IP_ADDRESS)
        
        for result in results:
            print(f"  File: {result.file_path}, Line: {result.line_number}")
            for match in result.matches:
                print(f"    Found: {match.group()}")
        
    finally:
        # Cleanup
        import shutil
        shutil.rmtree(temp_dir)
    
    print()

def example_data_extraction():
    """Example 4: Structured data extraction."""
    print("=" * 60)
    print("EXAMPLE 4: Data Extraction with Named Groups")
    print("=" * 60)
    
    tool = RegexTool()
    
    # Sample data with structured format
    data = """
    Product: iPhone 15, Price: $999.99, Stock: 50
    Product: Samsung Galaxy S24, Price: $899.99, Stock: 30
    Product: Google Pixel 8, Price: $699.99, Stock: 25
    Product: OnePlus 12, Price: $799.99, Stock: 15
    """
    
    # Pattern with named groups
    pattern = r'Product:\s*(?P<name>[^,]+),\s*Price:\s*\$(?P<price>[\d,]+\.?\d*),\s*Stock:\s*(?P<stock>\d+)'
    
    extracted_data = tool.extract_data(pattern, data)
    
    print("Extracted product data:")
    for i, item in enumerate(extracted_data):
        print(f"  {i+1}. {item['name']} - ${item['price']} (Stock: {item['stock']})")
    
    print()

def example_text_substitution():
    """Example 5: Text substitution and transformation."""
    print("=" * 60)
    print("EXAMPLE 5: Text Substitution")
    print("=" * 60)
    
    tool = RegexTool()
    
    # Example 1: Masking email addresses
    text1 = "Send reports to admin@company.com and backup to support@example.org"
    masked = tool.substitute(RegexPatterns.EMAIL, "[EMAIL_MASKED]", text1)
    
    print("Original:", text1)
    print("Masked:  ", masked)
    print()
    
    # Example 2: Formatting phone numbers
    text2 = "Call us at 5551234567 or 8005559999 for support"
    formatted = tool.substitute(r'(\d{3})(\d{3})(\d{4})', r'(\1) \2-\3', text2)
    
    print("Original:", text2)
    print("Formatted:", formatted)
    print()
    
    # Example 3: Converting dates
    text3 = "Meeting dates: 01/15/2024, 02/20/2024, 03/10/2024"
    iso_dates = tool.substitute(r'(\d{2})/(\d{2})/(\d{4})', r'\3-\1-\2', text3)
    
    print("Original:", text3)
    print("ISO format:", iso_dates)
    print()

def example_text_splitting():
    """Example 6: Text splitting with regex."""
    print("=" * 60)
    print("EXAMPLE 6: Text Splitting")
    print("=" * 60)
    
    tool = RegexTool()
    
    # Split by multiple delimiters
    text = "apple,banana;orange:grape|kiwi\tpineapple strawberry"
    parts = tool.split_text(r'[,;:|\s]+', text)
    
    print("Original text:", text)
    print("Split by multiple delimiters:")
    for i, part in enumerate(parts):
        if part.strip():
            print(f"  {i+1}. '{part}'")
    
    print()

def example_pattern_validation():
    """Example 7: Pattern validation."""
    print("=" * 60)
    print("EXAMPLE 7: Pattern Validation")
    print("=" * 60)
    
    tool = RegexTool()
    
    test_patterns = [
        r'\d+',  # Valid
        r'[a-zA-Z]+',  # Valid
        r'(?P<name>\w+)',  # Valid with named group
        r'[',  # Invalid - unclosed bracket
        r'(?P<invalid>unclosed',  # Invalid - unclosed group
        r'(?P<name>\w+):\s*(?P<value>\d+)'  # Valid complex pattern
    ]
    
    for pattern in test_patterns:
        validation = tool.validate_pattern(pattern)
        status = "✓ Valid" if validation['valid'] else "✗ Invalid"
        print(f"{status}: {pattern}")
        
        if validation['valid']:
            if validation['groups'] > 0:
                print(f"  Groups: {validation['groups']}")
            if validation['groupindex']:
                print(f"  Named groups: {list(validation['groupindex'].keys())}")
        else:
            print(f"  Error: {validation['error']}")
        print()

def example_output_formats():
    """Example 8: Different output formats."""
    print("=" * 60)
    print("EXAMPLE 8: Output Formats")
    print("=" * 60)
    
    tool = RegexTool()
    
    text = "Contact john@example.com or call (555) 123-4567 for more info."
    
    # Find emails and phones
    email_results = tool.find_matches(RegexPatterns.EMAIL, text)
    phone_results = tool.find_matches(RegexPatterns.PHONE_US, text)
    
    results = [email_results, phone_results]
    
    print("TEXT FORMAT:")
    print(RegexFormatter.format_text(results))
    print()
    
    print("JSON FORMAT:")
    print(RegexFormatter.format_json(results))
    print()
    
    print("CSV FORMAT:")
    print(RegexFormatter.format_csv(results))

def example_code_generation():
    """Example 9: Code generation from matches."""
    print("=" * 60)
    print("EXAMPLE 9: Code Generation")
    print("=" * 60)
    
    tool = RegexTool()
    
    # Sample code to analyze
    code_text = """
    def calculate_total(items):
        return sum(item.price for item in items)
    
    class UserManager:
        def add_user(self, user):
            self.users.append(user)
    
    def process_data(data):
        return [item for item in data if item.is_valid()]
    """
    
    # Find function definitions
    function_pattern = r'def\s+(\w+)\s*\([^)]*\):'
    class_pattern = r'class\s+(\w+):'
    
    func_results = tool.find_matches(function_pattern, code_text)
    class_results = tool.find_matches(class_pattern, code_text)
    
    results = [func_results, class_results]
    
    print("Generated code from regex matches:")
    print(tool.generate_code(results))

def example_advanced_features():
    """Example 10: Advanced features and flags."""
    print("=" * 60)
    print("EXAMPLE 10: Advanced Features")
    print("=" * 60)
    
    tool = RegexTool()
    
    # Case-insensitive matching
    text = "Hello WORLD hello world HELLO World"
    
    print("Case-sensitive matching:")
    result1 = tool.find_matches(r'hello', text)
    print(f"  Matches: {[m.group() for m in result1.matches]}")
    
    print("Case-insensitive matching:")
    import re
    result2 = tool.find_matches(r'hello', text, re.IGNORECASE)
    print(f"  Matches: {[m.group() for m in result2.matches]}")
    
    print()
    
    # Multiline matching
    multiline_text = """
    Start of document
    This is line 1
    This is line 2
    End of document
    """
    
    print("Multiline pattern matching:")
    pattern = r'^This.*$'
    
    print("Without MULTILINE flag:")
    result3 = tool.find_matches(pattern, multiline_text)
    print(f"  Matches: {len(result3.matches)}")
    
    print("With MULTILINE flag:")
    result4 = tool.find_matches(pattern, multiline_text, re.MULTILINE)
    print(f"  Matches: {[m.group().strip() for m in result4.matches]}")

def run_all_examples():
    """Run all examples."""
    print("Regex Tool - Comprehensive Examples")
    print("=" * 60)
    
    examples = [
        example_basic_pattern_matching,
        example_predefined_patterns,
        example_file_processing,
        example_data_extraction,
        example_text_substitution,
        example_text_splitting,
        example_pattern_validation,
        example_output_formats,
        example_code_generation,
        example_advanced_features
    ]
    
    for example in examples:
        try:
            example()
        except Exception as e:
            print(f"Error in {example.__name__}: {e}")
        print()

if __name__ == '__main__':
    run_all_examples()