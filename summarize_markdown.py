import argparse
import ollama
from pathlib import Path
import sys
import datetime


def summarize_file(input_path: Path, model: str, output_path: Path, prompt: str) -> None:
    try:
        text = input_path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Error reading input file: {e}")
        sys.exit(1)

    if not prompt:
        prompt = (
            "Please summarize the following content in **markdown format**, "
            "with bullet points, bold section headers, and concise phrasing:\n\n"
        )
    prompt = f"{prompt}\n{text}"

    print(f"Summarizing with model [{model}]...")
    try:
        response = ollama.chat(model=model, messages=[{"role": "user", "content": prompt}])
    except Exception as e:
        print(f"Error during summarization: {e}")
        sys.exit(1)

    summary = response.get("message", {}).get("content", "")
    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(summary, encoding="utf-8")
        print(f"✅ Summary saved to: {output_path}")
    except Exception as e:
        print(f"Error writing summary: {e}")
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize a file using Ollama")
    parser.add_argument("input", type=Path, help="Path to the input text file")
    parser.add_argument("--model", default="hf.co/unsloth/gemma-3n-E4B-it-GGUF:Q4_K_XL", help="Ollama model name")
    parser.add_argument("--output", type=Path, required=True, help="Path to save the summary")
    parser.add_argument("--prompt", default="", help="Optional custom prompt")
    args = parser.parse_args()

    if args.output is None:
        ts = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")
        out_name = args.input.stem + f"_summary_{ts}.md"
        args.output = Path.home() / ".zd" / "summaries" / out_name

    summarize_file(args.input, args.model, args.output, args.prompt)


if __name__ == "__main__":
    main()
