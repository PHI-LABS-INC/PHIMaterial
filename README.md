# PHI Material [![Open in Gitpod][gitpod-badge]][gitpod] [![Github Actions][gha-badge]][gha][![Foundry][foundry-badge]][foundry][![License: MIT][license-badge]][license]

[gitpod]: https://gitpod.io/#https://github.com/PHI-LABS-INC/DailyMaterial
[gitpod-badge]: https://img.shields.io/badge/Gitpod-Open%20in%20Gitpod-FFB45B?logo=gitpod
[gha]: https://github.com/PHI-LABS-INC/DailyMaterial/actions
[gha-badge]: https://github.com/PHI-LABS-INC/DailyMaterial/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

## 🏁 OverView

![OverView](/asset/phi.png)

The Phi platform is a sophisticated ecosystem comprised of a number of smart contracts, each with a specific role in the
game dynamics and user-generated content production.

These contracts key components are:

- PhiDaily.sol manages a daily reward system where users can earn coupons for regular logins and activity on Polygon.
  These coupons can be used to obtain MaterialObjects.

- EmissionLogic.sol controls the emission logic for MaterialObjects, managing their frequency and quantity.

- MaterialObject.sol and CraftableObject.sol: These contracts represent unique digital assets and the materials
  necessary to create them, respectively. Assets can take various forms such as in-game items or characters.

- CraftLogic.sol and UGCCraftLogic.sol: CraftLogic for managing the crafting process in a blockchain-based game. Users
  can create and update crafting recipes, each of which consists of materials and artifacts and potentially requires a
  catalyst.

- UGCCraftableObject.sol and UGCCraftableObjectFactory.sol: These contracts allow users to create their unique assets
  known as User Generated Content (UGC). These UGCCraftableObjects serve as materials and catalysts in CraftLogic
  recipes and are incorporated into the Phi ecosystem.

Thus, the Phi ecosystem fosters an interactive environment where users are encouraged to regularly engage and produce
content, driving the dynamics of the game while ensuring the continuous generation and distribution of assets.

## 🧐 Architecture

- Overview![OverView](/asset/image_overview.png)
- Sol2UML ![Sol2UML](/asset/classDiagram.svg)

### Get Coupon for Verify and Earn Material Object

If you make Polygon tx today, you can obtain coupons by using a cURL command to make a request to the API. Please
replace <Your Address> with your actual address.

```
 curl "https://utils-api.phi.blue/v1/philand/dailyquest/verify?address=<Your Address>"
```

## ✍️ Related Link

- [Phi CC0 Assets](https://github.com/PHI-LABS-INC/phi-objects)
- [Phi Quest](https://quest.philand.xyz/)
- [Polygon-phi-contract](https://github.com/PHI-LABS-INC/Polygon-phi-contract)

## 🔧 Contracts

- PhiDaily: 0xa4a057e817a220E4a9466E7877adbDB917a9d8D9
- EmissionLogic: 0x97895Ed981392b9d93e679E72bad1EA263d5De6F
- MaterialObject: 0x27996B7f37a5455E41aE6292fd00d21df1Fb82f1
- CraftableObject: 0xC73ea6afE94E5E473845Db007DB11a2E8a6847e0
- CraftLogic: 0x29a767519E9662f641a7B0b080f43E37aBc95557
- UGCCraftLogic: 0xDaB2195DdA177A01873d648d13A5EceC3Ad14D67
- UGCCraftableObjectFactory: 0x8D851B86cD299f9020a529A0975365eCFc1048BB
- UGCCraftableObject 0xc44be7Bb4753f3CDB45172f179a991F692878a56

## 🎈 License

This project is licensed under MIT.

## 🎉 Acknowledgements

- [Foundly template](https://github.com/PaulRBerg/foundry-template)
