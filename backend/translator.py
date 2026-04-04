from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
import torch
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_NAME = "facebook/nllb-200-distilled-600M"

# Load model with better error handling
try:
    logger.info(f"Loading model: {MODEL_NAME}")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME)
    logger.info("Model loaded successfully!")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    raise

# Move to GPU if available for faster translation
device = "cuda" if torch.cuda.is_available() else "cpu"
model = model.to(device)
logger.info(f"Using device: {device}")

LANGUAGE_CODES = {
    "bemba": "bem_Latn",
    "nyanja": "nya_Latn"
}

def translate_text(text, target_language):
    """
    Translate English text to target Zambian language
    
    Args:
        text (str): English text to translate
        target_language (str): Target language ('bemba' or 'nyanja')
    
    Returns:
        str: Translated text
    """
    try:
        # Validate inputs
        if not text or not text.strip():
            return "Please provide text to translate"
        
        target_language = target_language.lower()
        if target_language not in LANGUAGE_CODES:
            return f"Language '{target_language}' not supported. Use: {', '.join(LANGUAGE_CODES.keys())}"
        
        # Set source language to English
        tokenizer.src_lang = "eng_Latn"
        target_lang_code = LANGUAGE_CODES[target_language]
        
        # Tokenize input
        encoded = tokenizer(
            text, 
            return_tensors="pt",
            padding=True,
            truncation=True,
            max_length=512  # Prevent extremely long texts
        )
        
        # Move to same device as model
        encoded = {k: v.to(device) for k, v in encoded.items()}
        
        # Generate translation with improved parameters
        with torch.no_grad():  # Disable gradient calculation for faster inference
            generated_tokens = model.generate(
                **encoded,
                forced_bos_token_id=tokenizer.convert_tokens_to_ids(target_lang_code),
                max_length=200,  # Limit output length
                num_beams=5,     # Better quality translations
                early_stopping=True,
                no_repeat_ngram_size=3  # Avoid repetition
            )
        
        # Decode the output
        translation = tokenizer.batch_decode(
            generated_tokens,
            skip_special_tokens=True
        )[0]
        
        return translation
        
    except Exception as e:
        logger.error(f"Translation error: {e}")
        return f"Translation error: {str(e)}"

# Optional: Test function
if __name__ == "__main__":
    # Test the translation
    test_text = "Hello, how are you?"
    print(f"Translating: {test_text}")
    print(f"To Bemba: {translate_text(test_text, 'bemba')}")
    print(f"To Nyanja: {translate_text(test_text, 'nyanja')}")