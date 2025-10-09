find . -type f \
  -not -path "*/\.*" \
  -not -path "*/node_modules/*" \
  -not -path "*/bin/*" \
  -not -path "./bin/*" \
  -not -path "bin/*" \
  -not -name "*log" \
  -not -name ".env.local" \
  -not -name "*.xml*" \
  -not -name "LICENSE.md" \
  -not -name "*.md" \
  -not -name "*.sh" \
  -not -path "*/scripts/*" \
  -not -path "*/xslt/*" \
  -exec sh -c 'echo "===== $1 ====="; cat $1;
   echo ""' _ {} \;
