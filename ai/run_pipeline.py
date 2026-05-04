import embed_courses
import embed_sessions

if __name__ == "__main__":
    print("=== Embedding Courses ===")
    embed_courses.run()
    print("\n=== Embedding Sessions ===")
    embed_sessions.run()
    print("\nPipeline complete.")