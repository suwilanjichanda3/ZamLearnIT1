from translator import translate_text

# Test translations
test_cases = [
    ("Hello, how are you?", "bemba"),
    ("Good morning, welcome to Zambia", "nyanja"),
    ("Thank you very much", "bemba"),
    ("What is your name?", "nyanja"),
    ("I am learning Bemba", "bemba"),
]

print("=" * 50)
print("Testing Zambian Language Translator")
print("=" * 50)

for text, language in test_cases:
    result = translate_text(text, language)
    print(f"\nEnglish: {text}")
    print(f"To {language.upper()}: {result}")
    print("-" * 40)

# Test error handling
print("\n" + "=" * 50)
print("Testing Error Handling")
print("=" * 50)
print(f"Empty text: {translate_text('', 'bemba')}")
print(f"Invalid language: {translate_text('Hello', 'tonga')}")