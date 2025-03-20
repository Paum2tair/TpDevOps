exports.handler = async (event) => {
    // Obtenir la date et l'heure actuelles de Paris
    const parisTime = new Date().toLocaleString("fr-FR", { timeZone: "Europe/Paris" });

    // Nom à afficher
    const name = "Leantoine PONOEL";

    // Réponse de l'API
    const response = `Bonjour le monde, ici ${name} à ${parisTime}!`;

    return {
        statusCode: 200,
        body: response
    };
};