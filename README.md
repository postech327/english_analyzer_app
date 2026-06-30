# English Analyzer App

Flutter frontend for the English Analyzer learning application.

## Collaboration test

Start the FastAPI backend first:

```powershell
uvicorn main:app --reload --port 8001
```

Then run this frontend from the `english_analyzer_app` directory:

```powershell
flutter run -d chrome --dart-define=API_BASE=http://127.0.0.1:8001
```

The backend API should be available at <http://127.0.0.1:8001/>.
