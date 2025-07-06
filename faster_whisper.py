import argparse
from faster_whisper import WhisperModel


def main():
    parser = argparse.ArgumentParser(description="Transcribe audio using faster-whisper")
    parser.add_argument("audio", help="Input audio file")
    parser.add_argument("--model", default="large-v3", help="Model size or path")
    parser.add_argument("--device", default="cuda", help="Device to use")
    parser.add_argument("--output", required=True, help="Output text file")
    parser.add_argument("--beam_size", type=int, default=10, help="Beam search size")
    parser.add_argument("--language", default="en", help="Language code")
    args = parser.parse_args()

    model = WhisperModel(args.model, device=args.device, compute_type="float16")
    segments, info = model.transcribe(
        args.audio,
        beam_size=args.beam_size,
        language=args.language,
        vad_filter=True,
        condition_on_previous_text=False,
    )
    with open(args.output, "w", encoding="utf-8") as out:
        for segment in segments:
            out.write(segment.text + "\n")


if __name__ == "__main__":
    main()
