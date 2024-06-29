#!/bin/bash

echo "============================================"
echo "Installing WordPress"
echo "============================================"

# Install WordPress
curl -O https://wordpress.org/latest.tar.gz
tar -zxf latest.tar.gz
mv wordpress/* ./ &&
mv wp-content app/ &&
cp wp-config-sample.php wp-config.php &&
rm wp-config-sample.php &&

# Chemin vers le fichier wp-config.php
wp_config_path="wp-config.php"
# Créer des fichiers temporaires pour stocker les parties du fichier original
temp_file1=$(mktemp)
temp_file2=$(mktemp)

read -p "Domain (example.com): " user_domain &&

# Texte à ajouter pour WP_CONTENT_URL
text_to_add=$(cat << 'EOF'
// Define the new directory path and URL
define('WP_CONTENT_FOLDERNAME', 'app');
define('WP_CONTENT_DIR', ABSPATH . WP_CONTENT_FOLDERNAME);
define('WP_CONTENT_URL', 'https://hehe/' . WP_CONTENT_FOLDERNAME);
EOF
)

# Séparer le fichier original en deux parties
head -n 84 "$wp_config_path" > "$temp_file1"
tail -n +85 "$wp_config_path" > "$temp_file2"

# Combiner les parties avec le texte à ajouter pour WP_CONTENT_URL
cat "$temp_file1" > "$wp_config_path"
echo "$text_to_add" >> "$wp_config_path"
cat "$temp_file2" >> "$wp_config_path"

# Supprimer les fichiers temporaires
rm "$temp_file1" "$temp_file2"

echo "Le texte a été ajouté à la ligne 85 du fichier wp-config.php."

export LC_CTYPE=C
export LANG=C

generate_random_prefix() {
    # Generate a random string of 8 lowercase alphabetic characters
    prefix=$(tr -dc 'a-z' < /dev/urandom | head -c 8)
    echo "$prefix"
}

# Generate random prefix
random_prefix=$(generate_random_prefix)

# Check and display the generated prefix
if [[ ${#random_prefix} -ge 8 ]]; then
    echo "Generated prefix: ${random_prefix}_"
else
    echo "Error: Random prefix was not generated correctly."
    exit 1
fi

# Temporary file for modified wp-config.php
temp_config=$(mktemp)

# Replace "wp_" in wp-config.php with the generated prefix
sed "s/wp_/${random_prefix}_/g" "$wp_config_path" > "$temp_config" && mv "$temp_config" "$wp_config_path"


# Afficher un message de confirmation
echo "Le préfixe 'wp_' a été remplacé par '${random_prefix}_'."

chmod 444 wp-config.php

mkdir app/uploads &&
chmod 775 app/uploads &&

# Demander à l'utilisateur de spécifier le serveur
read -p "Quel est le serveur (nginx/apache) ? " server_type

# Vérification du serveur pour créer .htaccess si c'est Apache
if [[ "$server_type" == "apache" ]]; then
    echo "Serveur Apache détecté : génère les configurations spécifiques à Apache."

    echo "===================================================="
    echo "Create .htaccess at root with security rules for"
    echo "===================================================="

    cp config/.htaccess .htaccess &&

    echo "================================================="
    echo "Create .htaccess to protect uploads directory"
    echo "================================================="

    cat > app/uploads/.htaccess <<'EOF'

# Protect this file
<Files .htaccess>
    Require all denied
</Files>

# whitelist file extensions to prevent executables being
# accessed if they get uploaded
<Files *.php>
    Require all denied
</Files>
EOF

else
    echo "Serveur autre que Apache détecté : ne génère pas les configurations spécifiques à Apache."
fi

echo "Cleaning..."
rmdir wordpress
#rm -rf config

#remove zip file
rm latest.tar.gz
rm readme.html

echo "================================================="
echo "Success"
echo "================================================="
