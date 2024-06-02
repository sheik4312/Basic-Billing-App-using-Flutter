#include "firebase/firestore.h"
#include "firebase/app.h"

extern "C" {

// Firestore Get Documents Method
void GetDocuments(const char* collectionPath, std::vector<std::string>* results) {
    firebase::App* app = firebase::App::GetInstance();
    if (app == nullptr) {
        return;
    }

    firebase::firestore::Firestore* firestore = firebase::firestore::Firestore::GetInstance(app);
    if (firestore == nullptr) {
        return;
    }

    firebase::firestore::Query query = firestore->Collection(collectionPath);
    firebase::firestore::QuerySnapshot querySnapshot = query.Get();
    for (const auto& document : querySnapshot.documents()) {
        results->push_back(document.id());
    }
}

}
