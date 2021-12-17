#!/bin/bash

rm -rf release
rm -rf work

mkdir release

mkdir -p work/packages && cd work


echo "{
  \"packages\": [" > ./packages.json

packages=""

i=0
for line in $(cat ../packages); do
    name="$(echo $line | cut -d ',' -f1)"
    version="$(echo $line | cut -d ',' -f2)"
    url="https://github.com/MuonPi/$name/releases/download/$version/$name.zip"
    metadata="https://raw.githubusercontent.com/MuonPi/$name/$version/metadata.json"
    icon="https://raw.githubusercontent.com/MuonPi/$name/$version/resources/icon.png"
    path="org.github.MuonPi.$name"
    packages="$packages $path"

    mkdir "./packages/$path"
    wget "$icon" -P "./packages/$path"
    wget "$url"
   

    git clone "https://github.com/MuonPi/$name.git" && cd $name && git checkout $version

    if [ $i -gt 0 ]; then
        echo "," >> ../packages.json
    else
        ((i++))
    fi

    head metadata.json -n -3 | head -c -1 >> ../packages.json

echo ",
\"download_sha256\": \"$(sha256sum ../$name.zip | sed -E 's/\s(.*)//;t;d')\",
\"download_size\": $(du -csb ../$name.zip | grep total | sed 's/ *\stotal* *\(.*\)/\1/'),
\"install_size\": $(du -csb $(cat lib-files) | grep total | sed 's/ *\stotal* *\(.*\)/\1/'),
\"download_url\": \"$url\"" >> ../packages.json

    tail metadata.json -n 3 | head -c -1 >> ../packages.json
    cd ..

done


echo "
    ]
}" >> ./packages.json

cd packages

zip -r ../../release/resources.zip ${packages}

cd ../../

cat ./work/packages.json | jq . -M > ./release/packages.json

cp ./repository.in.json ./work/repository.json

echo "	\"packages\": {" >> ./work/repository.json
echo "		\"sha256\": \"$(sha256sum ./release/packages.json | sed -E 's/\s(.*)//;t;d')\"," >> ./work/repository.json
echo "		\"update_time_utc\": \"$(date -u +"%F %T")\"," >> ./work/repository.json
echo "		\"update_timestamp\": $(date -u +"%s")," >> ./work/repository.json
echo "		\"url\": \"https://archive.muonpi.org/kicad/packages.json\"" >> ./work/repository.json
echo "	}," >> ./work/repository.json

echo "	\"resources\": {" >> ./work/repository.json
echo "		\"sha256\": \"$(sha256sum ./release/resources.zip | sed -E 's/\s(.*)//;t;d')\"," >> ./work/repository.json
echo "		\"update_time_utc\": \"$(date -u +"%F %T")\"," >> ./work/repository.json
echo "		\"update_timestamp\": $(date -u +"%s")," >> ./work/repository.json
echo "		\"url\": \"https://archive.muonpi.org/kicad/resources.zip\"" >> ./work/repository.json
echo "	}" >> ./work/repository.json
echo "}" >> ./work/repository.json

cat ./work/repository.json | jq . -M > ./release/repository.json

rm -rf work
