exports.handler = async (event) => {
    // Obtenir la date et l'heure actuelles de Paris
    const parisTime = new Date().toLocaleString("fr-FR", { timeZone: "Europe/Paris" });

    // Nom à afficher
    const name = "Antoine NOEL";

    // Réponse de l'API
    const response = {
        message: `Bonjour, ${name}!`,
        date_time: parisTime
    };

    return {
        statusCode: 200,
        body: JSON.stringify(response)
    };
};