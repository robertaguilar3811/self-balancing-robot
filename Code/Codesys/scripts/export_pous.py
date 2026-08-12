import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "pous")

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

proj = projects.primary
app = proj.active_application

def export_obj(obj, path=""):
    name = obj.get_name(False)
    full_path = (path + "." + name) if path else name

    try:
        decl = obj.textual_declaration.text if hasattr(obj, "textual_declaration") and obj.textual_declaration else ""
        impl = obj.textual_implementation.text if hasattr(obj, "textual_implementation") and obj.textual_implementation else ""

        if decl or impl:
            filename = full_path.replace(".", "_") + ".st"
            filepath = os.path.join(OUTPUT_DIR, filename)
            with open(filepath, "w") as f:
                f.write("// PATH: " + full_path + "\n")
                f.write(decl)
                if impl:
                    f.write("\n" + impl)
            print("Exported: " + full_path + " -> " + filename)
    except Exception as e:
        print("Skipped: " + full_path + " (" + str(e) + ")")

    try:
        for child in obj.get_children(False):
            export_obj(child, full_path)
    except:
        pass

export_obj(app)
print("Export complete. Files in: " + OUTPUT_DIR)
