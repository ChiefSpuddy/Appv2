// ...existing code...

const handleSearch = async (searchTerm) => {
    try {
        // Split search term into name and set number
        const [name, setNumber] = searchTerm.trim().split(/\s+/);
        
        if (!name) return;

        const filteredCards = cards.filter(card => {
            const cardNameMatch = card.name.toLowerCase().includes(name.toLowerCase());
            
            // If set number is provided, match it exactly
            if (setNumber) {
                return cardNameMatch && card.number.toString() === setNumber.toString();
            }
            
            // If no set number provided, just match the name
            return cardNameMatch;
        });

        setFilteredResults(filteredCards);
    } catch (error) {
        console.error("Search error:", error);
        setFilteredResults([]);
    }
};

// Update any Firestore operations to use proper timestamp
const updateFirestore = async (data) => {
    try {
        await updateDoc(docRef, {
            ...data,
            updatedAt: serverTimestamp()
        });
    } catch (error) {
        console.error("Firestore update error:", error);
    }
};

// ...existing code...
