import numpy as np
from sentence_transformers import SentenceTransformer
import firebase_admin
from firebase_admin import credentials, firestore
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

SERVICE_ACCOUNT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "serviceAccount.json")

def init_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def build_course_text(doc: dict) -> str:
    title = doc.get("title") or doc.get("title", "")
    description = doc.get("short_description") or doc.get("shortDescription") or ""
    return f"{title}. {description}".strip()

def run():
    db = init_firebase()
    model = SentenceTransformer("all-MiniLM-L6-v2")

    print("Fetching courses from Firestore...")
    docs = db.collection("courses").stream()

    courses = []
    for doc in docs:
        data = doc.to_dict()
        text = build_course_text(data)
        if text:
            courses.append({"id": doc.id, "text": text})

    print(f"Embedding {len(courses)} courses...")
    texts = [c["text"] for c in courses]
    vectors = model.encode(texts, batch_size=32, show_progress_bar=True, normalize_embeddings=True)

    batch = db.batch()
    vectors_ref = db.collection("course_vectors")
    count = 0

    for i, course in enumerate(courses):
        vector = vectors[i].tolist()
        ref = vectors_ref.document(course["id"])
        batch.set(ref, {
            "vector": vector,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        count += 1
        if count % 400 == 0:
            batch.commit()
            batch = db.batch()
            print(f"Committed {count} vectors...")

    batch.commit()
    print(f"Done. Uploaded {len(courses)} course vectors.")

if __name__ == "__main__":
    run()