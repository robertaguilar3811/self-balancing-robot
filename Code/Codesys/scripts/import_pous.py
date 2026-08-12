import os
import re

INPUT_DIR = os.path.join(os.path.dirname(__file__), "pous")

proj = projects.primary
app = proj.active_application

BLOCK_KEYWORDS = [
    "PROGRAM", "FUNCTION_BLOCK", "FUNCTION",
    "METHOD", "ACTION", "PROPERTY",
]

BLOCK_END = {
    "PROGRAM": "END_PROGRAM",
    "FUNCTION_BLOCK": "END_FUNCTION_BLOCK",
    "FUNCTION": "END_FUNCTION",
    "METHOD": "END_METHOD",
    "ACTION": "END_ACTION",
    "PROPERTY": "END_PROPERTY",
}

def split_decl_impl(content):
    """Split a POU file into declaration and implementation."""
    # Find the VAR...END_VAR block(s) — they belong to declaration
    # Everything after the last END_VAR (and before END_PROGRAM etc.) is implementation
    lines = content.splitlines(True)

    # Strip the path comment line
    if lines and lines[0].startswith("// PATH:"):
        lines = lines[1:]

    content = "".join(lines)

    # Find the header keyword (PROGRAM, FUNCTION_BLOCK, etc.)
    header_match = None
    for kw in BLOCK_KEYWORDS:
        m = re.search(r"^" + kw + r"\b", content, re.MULTILINE)
        if m:
            header_match = m
            break

    if not header_match:
        return content, ""

    kw = header_match.group(0).strip()
    end_kw = BLOCK_END.get(kw, "END_" + kw)

    # Find the last END_VAR before the end keyword
    end_var_matches = [m for m in re.finditer(r"END_VAR", content)]
    end_kw_match = re.search(r"^" + re.escape(end_kw) + r"\b", content, re.MULTILINE)

    if end_var_matches and end_kw_match:
        last_end_var = end_var_matches[-1]
        decl = content[:last_end_var.end()].strip()
        impl_start = last_end_var.end()
        impl_end = end_kw_match.start()
        impl = content[impl_start:impl_end].strip()
        return decl, impl
    else:
        return content.strip(), ""

def find_obj(name):
    try:
        results = proj.find(name, recursive=True)
        if results:
            return results[0]
    except:
        pass
    return None

files = sorted(f for f in os.listdir(INPUT_DIR) if f.endswith(".st"))

for filename in files:
    filepath = os.path.join(INPUT_DIR, filename)
    with open(filepath, "r") as f:
        content = f.read()

    # Extract path from first line
    path = None
    if content.startswith("// PATH:"):
        path = content.split("\n")[0].replace("// PATH:", "").strip()

    if not path:
        print("Skipping (no path): " + filename)
        continue

    obj = find_obj(path)
    if not obj:
        # Try just the last component
        short_name = path.split(".")[-1]
        obj = find_obj(short_name)

    if not obj:
        print("Not found: " + path)
        continue

    decl, impl = split_decl_impl(content)

    try:
        if decl and hasattr(obj, "textual_declaration") and obj.textual_declaration:
            obj.textual_declaration.text = decl
        if impl and hasattr(obj, "textual_implementation") and obj.textual_implementation:
            obj.textual_implementation.text = impl
        print("Imported: " + path)
    except Exception as e:
        print("Error importing " + path + ": " + str(e))

print("Import complete.")
