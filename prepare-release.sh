#!/bin/bash
set -e

# Check parameters
VERSION=$1
COMPATLINK=$2
MILESTONE=$3
NOTES=$4
PUSH=$5
BUILD_DIR="build"
if [ $# != 5 ]
then 
  echo You must provide the product version, compat link, milestone, notes \(e.g. \"prepare_release.sh 3.3.0 \"https://github\" \"https://github\" \"Some notes\"\"\)
exit -1
fi

echo ::: Prepare splash :::
java -jar $BUILD_DIR/ImageLabeler-1.0.jar $VERSION 462 53 plugins/org.csstudio.product/splash-template.bmp plugins/org.csstudio.product/splash.bmp
echo ::: Change about dialog version :::
echo 0=$VERSION > plugins/org.csstudio.product/about.mappings

echo ::: Updating plugin versions ::
mvn -Dtycho.mode=maven org.eclipse.tycho:tycho-versions-plugin:0.20.0:set-version -DnewVersion=$VERSION -Dartifacts=product,products-csstudio-plugins,org.csstudio.product,org.csstudio.startup.intro,products-csstudio-features,org.csstudio.product.feature,org.csstudio.product.configuration.feature,repository
# update product because set-version doesn't
sed -i 's/\(\<product[^>]\+\? version=\"\)[^"]*\("[^>]\+\?>\)/\1'${VERSION}'\2/g'  repository/cs-studio.product

HTML="<h2>Version ${VERSION} - $(date +"%Y-%m-%d")</h2>
<ul>
<li>See specific application changelogs</li>
<li>${NOTES}</li>
<li><a href=\"${COMPATLINK}\" shape=\"rect\">Compatibility Notes and Know Bugs</a></li>
<li><a href=\"${MILESTONE}\" shape=\"rect\">Closed Issues</a></li>
</ul>"

# html encode &
HTML=$(echo $HTML | sed 's/&/\&amp;/g;')
# escape all backslashes first
HTML="${HTML//\\/\\\\}"
# escape slashes
HTML="${HTML//\//\\/}"
# escape asterisks
HTML="${HTML//\*/\\*}"
# escape full stops
HTML="${HTML//./\\.}"    
# escape [ and ]
HTML="${HTML//\[/\\[}"
HTML="${HTML//\[/\\]}"
# escape ^ and $
HTML="${HTML//^/\\^}"
HTML="${HTML//\$/\\\$}"
# remove newlines
HTML="${HTML//[$'\n']/}"

sed -i '/<\/p>/ a\ \n'"${HTML}" plugins/org.csstudio.startup.intro/html/changelog.html

echo ::: Committing and tagging version $VERSION :::
git commit -a -m "Updating changelog, splash, manifests to version $VERSION"
if [ "$PUSH" = "true" ]
then
  echo ::: Tagging version $VERSION :::
  git tag CSS-$VERSION
  echo ::: Pushing changes :::
  git push origin
  git push origin CSS-$VERSION
fi
