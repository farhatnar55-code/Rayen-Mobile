import firebase_admin
from firebase_admin import credentials, firestore
from sentence_transformers import SentenceTransformer
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

SERVICE_ACCOUNT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "serviceAccount.json")

def init_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def build_session_text(doc: dict) -> str:
    title = doc.get("title") or ""
    domain = doc.get("domain") or ""
    topic = doc.get("topic") or ""
    description = doc.get("description") or ""
    return f"{title}. {domain}. {topic}. {description}".strip()

def run():
    db = init_firebase()
    model = SentenceTransformer("all-MiniLM-L6-v2")

    print("Fetching training sessions from Firestore...")
    docs = db.collection("training_sessions").stream()

    sessions = []
    for doc in docs:
        data = doc.to_dict()
        status = data.get("status", "")
        if status != "published":
            continue
        text = build_session_text(data)
        if text:
            sessions.append({"id": doc.id, "text": text})

    print(f"Embedding {len(sessions)} sessions...")
    texts = [s["text"] for s in sessions]
    vectors = model.encode(texts, batch_size=32, show_progress_bar=True, normalize_embeddings=True)

    batch = db.batch()
    vectors_ref = db.collection("session_vectors")
    count = 0

    for i, session in enumerate(sessions):
        vector = vectors[i].tolist()
        ref = vectors_ref.document(session["id"])
        batch.set(ref, {
            "vector": vector,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        count += 1
        if count % 400 == 0:
            batch.commit()
            batch = db.batch()

    batch.commit()
    print(f"Done. Uploaded {len(sessions)} session vectors.")

if __name__ == "__main__":
    run()