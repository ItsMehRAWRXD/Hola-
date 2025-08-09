#!/usr/bin/env python3
"""
Full-Featured Regex Tool (RegexMaster)
A comprehensive regex utility for pattern matching, text processing, and program generation.
"""

import re
import sys
import os
import argparse
import json
import csv
from typing import List, Dict, Any, Optional, Union, Iterator
from pathlib import Path
import traceback
from dataclasses import dataclass
from enum import Enum


class OutputFormat(Enum):
    TEXT = "text"
    JSON = "json"
    CSV = "csv"
    XML = "xml"
    HTML = "html"


@dataclass
class MatchResult:
    pattern: str
    text: str
    matches: List[re.Match]
    file_path: Optional[str] = None
    line_number: Optional[int] = None


class RegexTool:
    """Comprehensive regex utility with advanced features."""
    
    def __init__(self):
        self.compiled_patterns = {}
        self.history = []
        self.flags = 0
        
    def compile_pattern(self, pattern: str, flags: int = 0) -> re.Pattern:
        """Compile and cache regex patterns for better performance."""
        cache_key = (pattern, flags)
        if cache_key not in self.compiled_patterns:
            try:
                self.compiled_patterns[cache_key] = re.compile(pattern, flags)
            except re.error as e:
                raise ValueError(f"Invalid regex pattern '{pattern}': {e}")
        return self.compiled_patterns[cache_key]
    
    def find_matches(self, pattern: str, text: str, flags: int = 0) -> MatchResult:
        """Find all matches of pattern in text."""
        compiled_pattern = self.compile_pattern(pattern, flags)
        matches = list(compiled_pattern.finditer(text))
        result = MatchResult(pattern=pattern, text=text, matches=matches)
        self.history.append(result)
        return result
    
    def substitute(self, pattern: str, replacement: str, text: str, 
                  count: int = 0, flags: int = 0) -> str:
        """Perform regex substitution."""
        compiled_pattern = self.compile_pattern(pattern, flags)
        return compiled_pattern.sub(replacement, text, count=count)
    
    def split_text(self, pattern: str, text: str, maxsplit: int = 0, 
                  flags: int = 0) -> List[str]:
        """Split text using regex pattern."""
        compiled_pattern = self.compile_pattern(pattern, flags)
        return compiled_pattern.split(text, maxsplit=maxsplit)
    
    def validate_pattern(self, pattern: str) -> Dict[str, Any]:
        """Validate regex pattern and return detailed information."""
        try:
            compiled = re.compile(pattern)
            return {
                "valid": True,
                "pattern": pattern,
                "groups": compiled.groups,
                "groupindex": compiled.groupindex,
                "flags": compiled.flags
            }
        except re.error as e:
            return {
                "valid": False,
                "pattern": pattern,
                "error": str(e),
                "error_type": type(e).__name__
            }
    
    def process_file(self, file_path: str, pattern: str, 
                    flags: int = 0) -> List[MatchResult]:
        """Process a file and find all matches."""
        results = []
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
                for line_num, line in enumerate(file, 1):
                    line = line.rstrip('\n\r')
                    result = self.find_matches(pattern, line, flags)
                    if result.matches:
                        result.file_path = file_path
                        result.line_number = line_num
                        results.append(result)
        except Exception as e:
            print(f"Error processing file {file_path}: {e}", file=sys.stderr)
        return results
    
    def process_directory(self, directory: str, pattern: str, 
                         file_pattern: str = r".*", flags: int = 0) -> List[MatchResult]:
        """Recursively process directory for matches."""
        results = []
        file_regex = re.compile(file_pattern)
        
        for root, dirs, files in os.walk(directory):
            for file in files:
                file_path = os.path.join(root, file)
                if file_regex.match(file):
                    results.extend(self.process_file(file_path, pattern, flags))
        return results
    
    def extract_data(self, pattern: str, text: str, 
                    group_names: Optional[List[str]] = None) -> List[Dict[str, str]]:
        """Extract structured data using named groups."""
        compiled_pattern = self.compile_pattern(pattern)
        matches = compiled_pattern.finditer(text)
        
        extracted_data = []
        for match in matches:
            if group_names:
                data = {name: match.group(i+1) if match.group(i+1) else "" 
                       for i, name in enumerate(group_names)}
            else:
                data = match.groupdict()
                if not data:  # If no named groups, use numbered groups
                    data = {f"group_{i}": group for i, group in enumerate(match.groups())}
            extracted_data.append(data)
        
        return extracted_data
    
    def generate_code(self, matches: List[MatchResult], template: str = None) -> str:
        """Generate code based on regex matches."""
        if not template:
            template = """
# Auto-generated code from regex matches
matches = {matches}

for match_data in matches:
    pattern = match_data['pattern']
    file_path = match_data.get('file_path', 'stdin')
    line_number = match_data.get('line_number', 0)
    
    print(f"Found pattern '{{pattern}}' in {{file_path}}:{{line_number}}")
    for match in match_data['matches']:
        print(f"  Match: {{match.group()}}")
        if match.groups():
            print(f"  Groups: {{match.groups()}}")
"""
        
        match_data = []
        for result in matches:
            match_data.append({
                'pattern': result.pattern,
                'file_path': result.file_path,
                'line_number': result.line_number,
                'matches': [{'match': m.group(), 'groups': m.groups(), 
                           'start': m.start(), 'end': m.end()} for m in result.matches]
            })
        
        return template.format(matches=json.dumps(match_data, indent=2))


class RegexFormatter:
    """Format regex results in various output formats."""
    
    @staticmethod
    def format_text(results: List[MatchResult]) -> str:
        """Format results as plain text."""
        output = []
        for result in results:
            if result.file_path:
                output.append(f"\n=== {result.file_path}:{result.line_number} ===")
            else:
                output.append(f"\n=== Pattern: {result.pattern} ===")
            
            for i, match in enumerate(result.matches):
                output.append(f"Match {i+1}: {match.group()}")
                if match.groups():
                    output.append(f"  Groups: {match.groups()}")
                output.append(f"  Position: {match.start()}-{match.end()}")
        
        return "\n".join(output)
    
    @staticmethod
    def format_json(results: List[MatchResult]) -> str:
        """Format results as JSON."""
        json_data = []
        for result in results:
            result_data = {
                "pattern": result.pattern,
                "file_path": result.file_path,
                "line_number": result.line_number,
                "matches": [
                    {
                        "match": match.group(),
                        "groups": match.groups(),
                        "start": match.start(),
                        "end": match.end(),
                        "groupdict": match.groupdict()
                    }
                    for match in result.matches
                ]
            }
            json_data.append(result_data)
        
        return json.dumps(json_data, indent=2)
    
    @staticmethod
    def format_csv(results: List[MatchResult]) -> str:
        """Format results as CSV."""
        import io
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header
        writer.writerow(["pattern", "file_path", "line_number", "match", 
                        "start", "end", "groups"])
        
        # Write data
        for result in results:
            for match in result.matches:
                writer.writerow([
                    result.pattern,
                    result.file_path or "",
                    result.line_number or "",
                    match.group(),
                    match.start(),
                    match.end(),
                    "|".join(match.groups()) if match.groups() else ""
                ])
        
        return output.getvalue()


class RegexPatterns:
    """Common regex patterns library."""
    
    EMAIL = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    URL = r'https?://(?:[-\w.])+(?:\:[0-9]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:\#(?:[\w.])*)?)?'
    IP_ADDRESS = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    PHONE_US = r'\b(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})\b'
    CREDIT_CARD = r'\b(?:\d{4}[-\s]?){3}\d{4}\b'
    DATE_ISO = r'\b\d{4}-\d{2}-\d{2}\b'
    TIME_24H = r'\b(?:[01]?[0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?\b'
    HEX_COLOR = r'#(?:[0-9a-fA-F]{3}){1,2}\b'
    MAC_ADDRESS = r'\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b'
    MARKDOWN_LINK = r'\[([^\]]+)\]\(([^)]+)\)'
    HTML_TAG = r'<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>(.*?)</\1>'
    
    @classmethod
    def get_pattern(cls, name: str) -> str:
        """Get a predefined pattern by name."""
        return getattr(cls, name.upper(), None)
    
    @classmethod
    def list_patterns(cls) -> List[str]:
        """List all available predefined patterns."""
        return [attr for attr in dir(cls) if not attr.startswith('_') and 
                not callable(getattr(cls, attr))]


def main():
    parser = argparse.ArgumentParser(
        description="Full-Featured Regex Tool - Comprehensive pattern matching utility",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Find emails in a file
  %(prog)s -p EMAIL -f document.txt
  
  # Search for custom pattern in directory
  %(prog)s -p "def\\s+(\\w+)" -d /path/to/code --file-pattern "*.py"
  
  # Extract data with named groups
  %(prog)s -p "(?P<name>\\w+):\\s*(?P<value>\\d+)" -f data.txt --extract
  
  # Substitute text
  %(prog)s -p "\\d+" -r "NUMBER" -f input.txt --substitute
  
  # Generate code from matches
  %(prog)s -p "class\\s+(\\w+)" -d ./src --generate-code
        """
    )
    
    # Pattern options
    parser.add_argument('-p', '--pattern',
                       help='Regex pattern to search for (or predefined pattern name)')
    parser.add_argument('-f', '--file', help='File to search in')
    parser.add_argument('-d', '--directory', help='Directory to search recursively')
    parser.add_argument('--file-pattern', default=r'.*',
                       help='Pattern to match filenames (default: all files)')
    
    # Text input
    parser.add_argument('-t', '--text', help='Text to search in directly')
    parser.add_argument('--stdin', action='store_true',
                       help='Read text from stdin')
    
    # Operations
    parser.add_argument('-r', '--replace', help='Replacement text for substitution')
    parser.add_argument('--substitute', action='store_true',
                       help='Perform substitution instead of finding matches')
    parser.add_argument('--split', action='store_true',
                       help='Split text using pattern')
    parser.add_argument('--extract', action='store_true',
                       help='Extract structured data using named groups')
    parser.add_argument('--validate', action='store_true',
                       help='Validate pattern syntax only')
    parser.add_argument('--generate-code', action='store_true',
                       help='Generate code from matches')
    
    # Flags
    parser.add_argument('-i', '--ignore-case', action='store_true',
                       help='Case-insensitive matching')
    parser.add_argument('-m', '--multiline', action='store_true',
                       help='Multiline mode')
    parser.add_argument('-s', '--dotall', action='store_true',
                       help='Dot matches newlines')
    parser.add_argument('-x', '--verbose', action='store_true',
                       help='Verbose regex mode')
    
    # Output options
    parser.add_argument('-o', '--output', choices=['text', 'json', 'csv'],
                       default='text', help='Output format')
    parser.add_argument('--output-file', help='Save output to file')
    parser.add_argument('--count', action='store_true',
                       help='Only show match count')
    
    # Utility options
    parser.add_argument('--list-patterns', action='store_true',
                       help='List all predefined patterns')
    parser.add_argument('--max-matches', type=int, default=0,
                       help='Maximum number of matches (0 = unlimited)')
    
    args = parser.parse_args()
    
    # List predefined patterns
    if args.list_patterns:
        patterns = RegexPatterns.list_patterns()
        print("Available predefined patterns:")
        for pattern_name in patterns:
            pattern = getattr(RegexPatterns, pattern_name)
            print(f"  {pattern_name.lower()}: {pattern}")
        return
    
    # Check if pattern is required for other operations
    if not args.pattern:
        parser.error("the following arguments are required: -p/--pattern")
    
    # Initialize regex tool
    tool = RegexTool()
    
    # Build regex flags
    flags = 0
    if args.ignore_case:
        flags |= re.IGNORECASE
    if args.multiline:
        flags |= re.MULTILINE
    if args.dotall:
        flags |= re.DOTALL
    if args.verbose:
        flags |= re.VERBOSE
    
    # Get pattern
    pattern = args.pattern
    predefined_pattern = RegexPatterns.get_pattern(args.pattern)
    if predefined_pattern:
        pattern = predefined_pattern
        print(f"Using predefined pattern '{args.pattern}': {pattern}")
    
    # Validate pattern if requested
    if args.validate:
        validation = tool.validate_pattern(pattern)
        print(json.dumps(validation, indent=2))
        return
    
    # Get input text
    text = None
    if args.text:
        text = args.text
    elif args.stdin:
        text = sys.stdin.read()
    
    results = []
    
    try:
        # Process input
        if args.file:
            results = tool.process_file(args.file, pattern, flags)
        elif args.directory:
            results = tool.process_directory(args.directory, pattern, 
                                           args.file_pattern, flags)
        elif text is not None:
            result = tool.find_matches(pattern, text, flags)
            if result.matches:
                results = [result]
        else:
            print("Error: No input specified. Use -f, -d, -t, or --stdin", 
                  file=sys.stderr)
            sys.exit(1)
        
        # Apply max matches limit
        if args.max_matches > 0:
            total_matches = sum(len(r.matches) for r in results)
            if total_matches > args.max_matches:
                count = 0
                filtered_results = []
                for result in results:
                    if count >= args.max_matches:
                        break
                    remaining = args.max_matches - count
                    if len(result.matches) <= remaining:
                        filtered_results.append(result)
                        count += len(result.matches)
                    else:
                        # Truncate matches in this result
                        result.matches = result.matches[:remaining]
                        filtered_results.append(result)
                        break
                results = filtered_results
        
        # Handle operations
        if args.substitute and args.replace is not None:
            if text is not None:
                output = tool.substitute(pattern, args.replace, text, flags=flags)
                print(output)
            else:
                print("Error: Substitution requires text input (-t or --stdin)", 
                      file=sys.stderr)
                sys.exit(1)
            return
        
        if args.split:
            if text is not None:
                parts = tool.split_text(pattern, text, flags=flags)
                for i, part in enumerate(parts):
                    print(f"Part {i+1}: {repr(part)}")
            else:
                print("Error: Split requires text input (-t or --stdin)", 
                      file=sys.stderr)
                sys.exit(1)
            return
        
        if args.extract:
            if text is not None:
                extracted = tool.extract_data(pattern, text)
                print(json.dumps(extracted, indent=2))
            else:
                print("Error: Extract requires text input (-t or --stdin)", 
                      file=sys.stderr)
                sys.exit(1)
            return
        
        if args.generate_code:
            code = tool.generate_code(results)
            print(code)
            return
        
        # Show count only
        if args.count:
            total_matches = sum(len(r.matches) for r in results)
            print(f"Total matches: {total_matches}")
            return
        
        # Format output
        if args.output == 'json':
            output = RegexFormatter.format_json(results)
        elif args.output == 'csv':
            output = RegexFormatter.format_csv(results)
        else:
            output = RegexFormatter.format_text(results)
        
        # Save or print output
        if args.output_file:
            with open(args.output_file, 'w', encoding='utf-8') as f:
                f.write(output)
            print(f"Output saved to {args.output_file}")
        else:
            print(output)
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        if args.verbose:
            traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()