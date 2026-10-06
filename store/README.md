# Morning Flight — App Store notes

- App Store Connect app id 6819866579, bundle id uk.co.themorningflight.app (bundle id record 8R445LPVUU), team 8759KGVN28.
- Version 1.0 id ac5fed32-4fcf-43d7-8dfc-ea2d70e90086, en-GB localisation 862183a1-9210-434e-b669-bc8e4580e3ee, appInfo df40934b-8d8a-4b45-915e-230ec8b49a30.
- Subscription group 22448144 "Morning Flight Premium". Products the app expects: uk.co.themorningflight.premium.monthly (£4.99) and uk.co.themorningflight.premium.annual (£39.99), 7-day free trial.
- TestFlight internal group 47a36a91-723c-48fe-a745-40f34eed8051 (access to all builds).
- Signing: Apple Distribution cert 529GT85345 whose key lives in ~/Library/Keychains/mf-dist.keychain-db (password mfpass, files in ~/.appstoreconnect/dist). App Store profile "Morning Flight App Store".

## Build and upload
    npm run sync
    cd ios/App && xcodebuild -project App.xcodeproj -scheme App -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/mf.xcarchive -derivedDataPath /tmp/mf-derived archive -allowProvisioningUpdates -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_DQ5S795352.p8 -authenticationKeyID DQ5S795352 -authenticationKeyIssuerID 69a6de79-7454-47e3-e053-5b8c7c11a4d1
    security unlock-keychain -p mfpass ~/Library/Keychains/mf-dist.keychain-db
    xcodebuild -exportArchive -archivePath /tmp/mf.xcarchive -exportPath /tmp/mf-export -exportOptionsPlist store/export.plist
    xcrun altool --upload-app -f /tmp/mf-export/App.ipa -t ios --apiKey DQ5S795352 --apiIssuer 69a6de79-7454-47e3-e053-5b8c7c11a4d1
Bump CURRENT_PROJECT_VERSION in ios/App/App.xcodeproj/project.pbxproj before each upload.
