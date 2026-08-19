# Migration Inventory: smart-pos-mobile -> Flutter

Source audited: `smart-pos-mobile` (Ionic 3 / Cordova / Angular, `com.kingpower.kpgsmartpos` v4.6.1).
53 page classes across `src/pages`, 13 provider files across `src/providers` (+1 HTTP interceptor module).

## 0. Methodology (read this before the tables)

`src/app/app.module.ts` registers pages in three places: `declarations`, `entryComponents`, and an
`IonicModule.forRoot(... { links: [...] })` deep-link table. **None of these three lists is a reliable
signal of "is this page actually used."** Ionic 3's `NavController.push()` / `ModalController.create()`
accept a component **class reference or a string name** directly — they do not require a `links` entry to
navigate. Conversely, a page can be fully registered (declared, in `entryComponents`, with a `links`
segment) and never be the target of any `push`/`setRoot`/`modalCtrl.create` call anywhere in the app.

Confirmed example: `AboutPage`, `ContactPage`, `SpecialDiscountPage` are imported under a `// unused page`
comment in `app.module.ts`. `AboutPage`/`ContactPage` genuinely have zero inbound navigation calls
anywhere — dead. But `SpecialDiscountPage` **is** reachable: `checkout.ts:3342` calls
`this.navCtrl.push("SpecialDiscountPage", { order: this.order })` — a live, string-based push. The
`// unused page` comment and duplicate `links` entry are stale/misleading; the page is active.

**Method used here:** for every page class, grep the entire `src/` tree (pages, providers, components) for
real navigation call sites — `navCtrl.push(...)`, `navCtrl.setRoot(...)`, `app.getRootNav().push/setRoot(...)`,
`modalCtrl.create(...)` — using both class-reference and string-literal forms (Ionic 3 supports both
interchangeably once the class is in `entryComponents`). A page counts as **ACTIVE** only if at least one
such real call site targeting it was found, traced from the actual entry point
(`app.component.ts` → `rootPage = LoginPage`). A page with imports/declarations but **zero** inbound
navigation call sites is flagged **ORPHANED/DEAD**, even if it has a `links` segment.

Result: **53 page classes total → 43 ACTIVE, 10 ORPHANED/DEAD.**
(13 provider files → 12 ACTIVE, 1 explicitly unused — `member-service-notuse`.)

Entry flow: `LoginPage` (root) → on success `HomePage` (default) or `CustomerFormPage` (if
`settings.defaultPage` overridden) → `AppMenuPage` / `SettingsPage` from the hamburger menu, and
`CustomerPage` → `SalePage` → `CheckoutPage` as the core sales flow, with `CheckoutPage` acting as a hub
that modally opens most of the payment-method pages.

---

## 1. Active pages

Table columns: **APIs** lists the provider + method(s) actually observed being called from that page
(verified by grep for the heavier/hub pages: login, home, customer, sale, checkout, payment, settings,
customer-form; inferred with high confidence from imported models/providers for the smaller
picker/modal pages — these typically call exactly one provider method matching their imported contract
model). **Assets** defaults to "KP custom fonts + ion-icon font icons (global, no page-specific images)"
unless the page's `.html` references `assets/imgs/...` directly or embeds a card component that does
(`claim-check-card`, `enquiry-card` use `assets/imgs/card-corner/*`, `assets/imgs/card/*`; payment/member
pages use `assets/imgs/card-icons/*`).

| Route / Segment | Page | Purpose | Models | Providers (DI) | APIs (provider.method) | Assets | Permissions / Plugins | Hardware |
|---|---|---|---|---|---|---|---|---|
| `login` | LoginPage | Auth entry point: login form, machine-env check, AOT login | AuthenModel, RCAgentModel, Interface | AuthServiceProvider, SettingsProvider, ShareDataProvider, RCAgentAOTProvider, SunmiServiceProvider, AppVersion, AppUpdate | authservice.login(), authservice.setLoggedin(), authservice.GetEnvMachineRealTime(), rcAgentService.onLogIn() | login logo/background img (commented out) | BarcodeScanner (constructor DI, unused for login itself), AppUpdate | none directly (AOT login + Sunmi provider injected but not fired here) |
| `home` | HomePage | Post-login dashboard; passport/boarding-pass MRZ scan → go to CustomerPage | AuthenModel | AuthServiceProvider, SaleEngineProvider, ShareDataProvider, SettingsProvider, PrinterProvider, RCAgentAOTProvider | authservice.hasLoggedIn/getSessionKey/logout/GetEnvMachineRealTime/getPassportByMRZ(), saleEngine.getDateTimeServer(), rcAgentService.onCheckStatusSever() | `assets/imgs/cn-online-sale-salecate-*.png` (promo banner) | BarcodeScanner (MRZ/passport scan) | Barcode/MRZ scanner (camera or HW scanner), Bluetooth printer (via PrinterProvider), AOT RCAgent status check |
| `appMenu` | AppMenuPage | Hamburger side menu: app version, settings, logout | — | AuthServiceProvider, PrinterProvider, SettingsProvider, ShareDataProvider, AppVersion | none (navigation hub only) | ion-icons only | AppVersion | none |
| `settings` | SettingsPage | POS machine config: branch, module, endpoints, default page, sub-branch, pickup codes, device UUID | settings, SubBranchModel, PickupModel | SettingsProvider, ShareDataProvider, PickupServiceProvider, SaleEngineProvider | shareData.getListSubBranch/getPickupCodeList/getmPOSType() | none page-specific | UniqueDeviceID (device binding) | none |
| `no-internet` | NoInternetPage | Offline/connectivity fallback screen (setRoot target on network loss) | — | — | none | none | Network (app-level watcher triggers setRoot to this page) | none |
| `customer/:id` | CustomerPage | Customer detail/search hub; entry to Sale/Checkout/Enquiry/Pickup | CustomerModel, SaleEngineContract, OrderClass, AuthenModel, ReturnObject | AuthServiceProvider, SettingsProvider, SaleEngineProvider, ShareDataProvider, RCAgentAOTProvider | authservice.hasLoggedIn/getSessionKey/logout/changeOrderType/checkOrderType/getOrderType(), saleEngine.getOrder/getShoppingInfo/getConfigPos/clearSession(), shareData.canDoIt() | card-icons (member tier badges) | BarcodeScanner (customer/loyalty card scan) | Barcode scanner |
| `customer-form/:id` | CustomerFormPage | New/edit customer registration; passport MRZ scan, nationality/agent/flight pickers | CustomerModel, FlightClass, SaleEngineContract, PassportฺBoardingModel, ReturnObject | SaleEngineProvider, SettingsProvider, FlightProvider, AuthServiceProvider, PrinterProvider, ShareDataProvider | saleEngine.regsiter(), authservice.getPassportByMRZ() | `assets/imgs/wallbar.jpg` (background) | BarcodeScanner (MRZ scan) | Barcode/MRZ scanner, Bluetooth printer (via PrinterProvider) |
| `sale/:shoppingCard` | SalePage | Main POS cart/basket: add items, discounts, promotions, checkout hand-off | SaleEngineContract, OrderClass, ReturnObject, AuthenModel, CustomerModel | SaleEngineProvider, AuthServiceProvider, SettingsProvider, ShareDataProvider, RCAgentAOTProvider | authservice.hasLoggedIn/getSessionKey/logout/unsetLoggedin(), saleEngine.addItemToOrder/actionListItemToOrder/getOrder/saveOrder/reverseVirtualStock/updateOrderStatus(), shareData.canDoIt() | card/product icons | BarcodeScanner (article barcode scan) | Barcode scanner |
| `checkout/:shoppingCard` | CheckoutPage | Checkout/payment orchestration hub — opens most payment-method modals | AuthenModel, MemberModel, CustomerModel, RCAgentModel, ReturnObject, PaymentModel, SaleEngineContract, OrderClass | AuthServiceProvider, SaleEngineProvider, SettingsProvider, PrinterProvider, CashCardProvider, RCAgentAOTProvider, ShareDataProvider, SunmiServiceProvider | authservice.getSessionKey/hasLoggedIn/logout(), saleEngine.getOrder/getPaymentMethodList/checkOutPaymentOrder/actionPaymentToOrder/updateOrderStatus/validateGWP/getDateTimeServer(), rcAgentService.onNewReceipt/onLogOutAOT() | payment-method icons (Visa/Mastercard/Alipay/WeChat/etc.) | BluetoothSerial (transitively via PrinterProvider) | Bluetooth thermal printer (Woosim), Sunmi built-in printer, AOT tax-receipt agent |
| `paymentmethod` | PaymentMethodPage | Payment method selection UI (modal, list passed in via params) | PaymentModel | SaleEngineProvider, SettingsProvider | none own call — list supplied by CheckoutPage | payment icons | — | none |
| `payment/:shoppingCard` | PaymentPage | Payment gateway processing (card/QR wallet) | PaymentModel, SaleEngineContract, OrderClass, settings, AuthenModel | SaleEngineProvider, AuthServiceProvider, SettingsProvider, PaymentGatewayProvider | authservice.getEnvironment/getSessionKey(), paymentGateway.payment(), saleEngine.actionOrderPayment/addPaymentToOrder/getOrder/getWalletTypeFromBarcode() | payment icons | BarcodeScanner (wallet barcode) | Barcode scanner, external EDC/payment gateway (network) |
| — (modal from Checkout) | CustomerProfilePage | Customer profile/loyalty detail within checkout | AuthenModel, OrderClass, CustomerModel, SaleEngineContract | SettingsProvider, SaleEngineProvider, AuthServiceProvider, RCAgentAOTProvider | saleEngine.getOrder(), likely saleEngine.GetCaratInformation() | member card-tier icons | — | none |
| `change` | ChangePage | Change/currency exchange calculation on payment | SaleEngineContract, OrderClass, PaymentModel | SaleEngineProvider, AuthServiceProvider, SettingsProvider | saleEngine.exchangeCurrency(), saleEngine.actionOrderPayment() (inferred) | none | — | none |
| `signature-pad` | SignaturePadPage | Capture customer signature | — | (none imported) | saleEngine.SaveSignature() called by caller, not this page | canvas only | — | Touchscreen (canvas signature capture — `angular2-signaturepad`, not a native plugin) |
| `voucher` | VoucherPage | Apply voucher/gift-card barcode to order | PaymentModel, OrderClass, SaleEngineContract | AuthServiceProvider, SaleEngineProvider, SettingsProvider | saleEngine.addVoucher() | voucher icon | BarcodeScanner | Barcode scanner |
| `cashcard` | CashCardPage | Check/apply King Power Cash Card balance | PaymentModel, SaleEngineContract, OrderClass | SaleEngineProvider, CashCardProvider, AuthServiceProvider, SettingsProvider | cashCardProvider.checkCard(), saleEngine.addPaymentToOrder() (inferred) | cashcard icon | — | Card reader/scanner (magstripe or barcode, implicit) |
| `payment-form` | PaymentFormPage | Bank/credit-card payment entry form (EDC) | PaymentModel, OrderClass, SaleEngineContract, ReturnObject, MemberModel | SaleEngineProvider, AuthServiceProvider, SettingsProvider | saleEngine.getBankOfEDCList(), saleEngine.addPaymentToOrder/actionOrderPayment() (inferred) | bank/card icons | — | EDC/card payment terminal (external device, integration implicit via bank code list) |
| `epurse-payment` | EpursePaymentPage | e-Purse (member wallet) payment | PaymentModel, OrderClass | SettingsProvider, AuthServiceProvider, SaleEngineProvider | saleEngine.actionOrderPayment/addPaymentToOrder() (inferred) | e-purse icon | — | none |
| `shippingaddress` | ShippingaddressPage | Delivery/shipping address entry for online-order pickup | SaleEngineContract, CustomerModel | SettingsProvider, AuthServiceProvider, SaleEngineProvider | saleEngine.getShippingAddress/updateShippingAddress() | none | — | none |
| `payment-2c2p` | Payment2C2PPage | 2C2P / Alipay / WeChat QR payment gateway | PaymentModel, AuthenModel, OrderClass | SettingsProvider, SaleEngineProvider, PaymentGatewayProvider, AuthServiceProvider | paymentGateway.GenerateQRPay/Query/SessionAbort/SlipText(), saleEngine.addPaymentToOrder() (inferred) | Alipay/WeChat icons | — | QR payment gateway (network-based, no local HW) |
| `special-discount` | SpecialDiscountPage | Manual special discount (promoter/DFA authorized) — **note: reachable only via string push, marked "unused" in app.module** | OrderClass, SaleEngineContract, PaymentModel | AuthServiceProvider, SaleEngineProvider, SettingsProvider, ShareDataProvider | saleEngine.getPromotionList/actionListItemToOrder() (inferred) | none | — | none |
| `payment-history` | PaymentHistoryPage | View payment/transaction history for an order | OrderClass, SaleEngineContract, PaymentModel | SaleEngineProvider, AuthServiceProvider, PrinterProvider | saleEngine.findPaymentHistory() | none | BluetoothSerial (via PrinterProvider) | Bluetooth printer |
| `currency-picker/:shoppingCard` | CurrencyPickerPage | Select display/payment currency | SaleEngineContract | SaleEngineProvider, SettingsProvider, AuthServiceProvider | saleEngine.getCurrency() | flag/currency icons | — | none |
| `total-grand/:shoppingCard` | TotalGrandPage | Grand-total summary display | OrderClass | SettingsProvider only | none — pure display, data passed via nav params | none | — | none |
| `edit-sale/:shoppingCard/:itemId` | EditSalePage | Edit quantity/attributes of a cart line item | OrderClass, SaleEngineContract | AuthServiceProvider, SaleEngineProvider, ShareDataProvider, SettingsProvider | saleEngine.actionItemToOrder() | none | — | none |
| `discount/:shoppingCard/:itemId` | DiscountPage | Apply item-level discount/promotion | OrderClass, SaleEngineContract | AuthServiceProvider, SaleEngineProvider, SettingsProvider, ShareDataProvider | saleEngine.actionItemToOrder/getPromotionList() (inferred) | none | — | none |
| `cashback-discount` | CashbackDiscountPage | Apply cashback coupon to order | OrderClass, CouponCashback | SaleEngineProvider, SettingsProvider, AuthServiceProvider | saleEngine.ActionCouponInOrder() | none | — | none |
| — (modal from Sale) | GuidingPage | Static onboarding/help slideshow (no API) | — | (none) | none | `assets/imgs/ica-slidebox-img-4.png` | — | none |
| `promoter-dfa-picker` | PromoterDfaPickerPage | Select promoter/DFA staff code for order | SaleEngineContract | SaleEngineProvider, SettingsProvider | saleEngine.getPromoterDFA() | none | — | none |
| `article-info` | ArticleInfoPage | Display article/product detail (VAS item info) | OrderClass, OutputDLL | (none — receives data via nav params from SalePage, which already called `GetMasterByBarcodeDLL`) | none own | product image (from data) | — | none |
| `flightCode` | FlightPage | Lookup flight by code for customer boarding info | FlightClass | FlightProvider, SettingsProvider, ShareDataProvider | flightProvider.getFlightByCode/getDateByFlight/validateFlight() | none | — | none |
| `national/:national` | NationalityPage | Nationality picker | CustomerModel | SaleEngineProvider | saleEngine.getNationality() | flag icons | — | none |
| `customertype-picker/customertype` | CustomertypePickerPage | Customer type picker | SaleEngineContract | SaleEngineProvider, SettingsProvider | saleEngine.getListAgent() (inferred, shared with agent picker) | none | — | none |
| `guidpicker` | GuidPickerPage | Sub-agent / tour-guide picker | SaleEngineContract | SaleEngineProvider, SettingsProvider | saleEngine.getListAgent() | none | — | none |
| `agentpicker` | AgentPickerPage | Travel agent picker | SaleEngineContract | SaleEngineProvider, SettingsProvider | saleEngine.getListAgent() | none | — | none |
| `shoppingcard` | ShoppingcardPage | Shopping/claim-card print preview and print trigger | CustomerModel | SaleEngineProvider, PrinterProvider, SunmiServiceProvider | printerProvider.PrintShoppingCard(), sunmiService.printShoppingCard() | none | BluetoothSerial | Bluetooth printer (Woosim) or Sunmi built-in printer |
| `enquiry/:shoppingCard` (also `enquiry`) | EnquiryPage | Order enquiry/search list | FilterModel, CustomerModel, SaleEngineContract, OrderClass | SettingsProvider, SaleEngineProvider, AuthServiceProvider | saleEngine.getOrderList() | claim-status icons (via enquiry-card component) | — | none |
| `pickup/:shoppingCard` | PickupPage | Pickup-counter list; create pickup document & print | FilterModel, CustomerModel, OrderClass, ReturnObject, PickupModel, SaleEngineContract | SettingsProvider, PickupServiceProvider, AuthServiceProvider | pickupService.getPickingList/createPickingList/sendToPrinter() | none | — | Print Hub (network print) — no local Bluetooth call observed in this page |
| `claim-check/:shoppingCard` | ClaimcheckPage | Claim check / tax invoice print for order | OrderClass, CustomerModel, PaymentModel, RefundModel | AuthServiceProvider, SaleEngineProvider, PrinterProvider, SettingsProvider | saleEngine.printTaxInvoice/refundOrderPayment() (inferred), printerProvider.PrintInvoice() | `assets/imgs/card-corner/claim_*.png` (via claim-check-card) | BluetoothSerial | Bluetooth printer |
| `enquiry-detail-modal` | EnquiryDetailModalPage | Order detail modal from enquiry results (refund, print) | OrderClass, SaleEngineContract, EnquiryModels, PaymentModel, RefundModel | SettingsProvider, SaleEngineProvider, AuthServiceProvider, PrinterProvider | saleEngine.findPaymentHistory/refundOrderPayment() | claim-status icons | BluetoothSerial | Bluetooth printer |
| `member-info` | MemberInfoPage | Display King Power member/loyalty card info | — | SettingsProvider only | none own — data passed via modal params (caller likely used saleEngine.GetCaratInformation) | member card-tier icons | — | none |
| `amount-remaining-modal` | AmountRemainingModalPage | Quick-pay remaining-balance entry modal (2C2P flow) | — | (none — pure UI, `Keyboard` plugin only) | none | none | Keyboard | none |
| `promotion-picker` | PromotionPickerPage | Promotion selection picker (modal, used by Discount and SpecialDiscount) | SaleEngineContract | SettingsProvider, SaleEngineProvider | saleEngine.getPromotionList/getPromotion() | none | — | none |

**43 active pages total.**

**Not yet grep-verified line-by-line (inferred from imported models/providers, flagged "(inferred)" above)** —
spot-check before relying on these for API-contract work in task 1.2: CustomerProfilePage, ChangePage,
PaymentFormPage, EpursePaymentPage, MemberInfoPage, SpecialDiscountPage, DiscountPage, CashCardPage.

---

## 2. Providers inventory (`src/providers/*`)

| Provider (file) | Responsibility | Key methods | Backend domain / endpoint base | Consumer pages |
|---|---|---|---|---|
| `AuthServiceProvider` (auth-service/auth-service.ts) | Login/session lifecycle, token storage (Ionic Storage), order-type change/DFA orchestration, MRZ passport parsing (`mrz` npm lib) | `login`, `logout`, `hasLoggedIn`, `setLoggedin`, `getLoggedinData`, `getSessionKey`, `getEnvironment`, `getHasPermission`, `GetEnvMachineRealTime`, `RCRequest`, `getOrderType`/`checkOrderType`/`changeOrderType` (+ their `*Api` helpers w/ OAuth token), `getOAuthToken`, `getPassportByMRZ`, `getConfigPos` | Sale Engine `{saleEngineEndpoint}/Authen/*`, `/SaleEngine/GetConfigPos`, external Order Gateway API (OAuth client-credentials flow) | login, home, customer, customer-form, customer-profile, sale, checkout, payment, payment-2c2p, payment-form, payment-history, cash-card, change, currency-picker, discount, edit-sale, enquiry, enquiry-detail-modal, claimcheck, shippingaddress, voucher, epurse-payment, special-discount, cashback-discount, app-menu, scan-customer(dead), about(dead) |
| `SaleEngineProvider` (sale-engine/sale-engine.ts) | Core POS/order domain — cart, payment, promotion, currency, enquiry, agents, articles | 30+ methods: `getOrder`, `addItemToOrder`, `actionItemToOrder`, `actionListItemToOrder`, `saveOrder`, `getCurrency`, `getPaymentMethodList`, `addOrderPayment`/`addPaymentToOrder`/`actionOrderPayment`/`actionPaymentToOrder`, `checkOutPaymentOrder`, `finishPaymentOrder`, `getPromotionList`/`getPromotion`/`getPromotionQr`, `validateGWP`, `ValidatePromotionMember`, `getNationality`, `printTaxInvoice`, `exchangeCurrency`, `getBankOfEDCList`, `updateOrderStatus`, `getListAgent`, `clearSession`, `sendEmail`, `getOrderList`, `getDateTimeServer`, `findPaymentHistory`, `refundOrderPayment`, `SaveSignature`, `reverseVirtualStock`, `addVoucher`, `updateShippingAddress`/`getShippingAddress`, `getConfigPos`, `getmPOSType`, `getPromoterDFA`, `SaveUpdateRCode`, `GetMasterByBarcodeDLL`, `GetCaratInformation`, `ActionCouponInOrder`, `getCustomerInfo`, `regsiter` | Sale Engine `{saleEngineEndpoint}/SaleEngine/*`; Register `{webServiceEndpoint}/Register/*` | Almost every active page except login, no-internet, total-grand, article-info, guiding, member-info, amount-remaining-modal |
| `SettingsProvider` (settings/settings.ts) | App-wide config singleton: branch, module key, service endpoints, default page, device UUID — persisted via `@ionic/storage` | `get()`, `set()`, `setResourceName`/`getResourceName` | Local storage only (no HTTP) | Nearly all pages (injected for `settings.*Endpoint` values / currency formatting) |
| `PaymentGatewayProvider` (payment-gateway-service/PaymentGatewayProvider.ts) | External Payment Gateway aggregator (EDC/QR/Alipay/WeChat) | `payment`, `Query`, `Cancel`, `SessionAbort`, `SlipText`, `GenerateQRPay` | Payment Gateway (`URLService` passed per-call, from bank/EDC config, not a fixed settings field) | payment, payment-2c2p |
| `CashCardProvider` (cashcard-service/CashCardProvider.ts) | King Power Cash Card domain | `checkCard` | `{cashCardApi}/CashCard/CheckCard` | cash-card, checkout |
| `FlightProvider` (flight-service/FlightProvider.ts) | Flight lookup domain (duplicate `getCustomerInfo` also exists on SaleEngineProvider — inconsistency to resolve during migration) | `getCustomerInfo`, `getFlightByCode`, `getDateByFlight`, `validateFlight` | `{flightApi}/flight/*`; also a dead hardcoded `URL_FLIGHT` constant (`api2.kingpower.com/flightapi/`, unused) | flight, customer-form |
| `PickupServiceProvider` (pickup-service/pickup-service.ts) | Pickup / Print Hub domain | `getPickingList`, `createPickingList`, `sendToPrinter` | Sale Engine `/Pickup/*`; Print Hub `{printHubEndpoint}/Printer/PrintPickupDocument` | pickup, settings |
| `PrinterProvider` (printer/printer.ts) | Bluetooth thermal printer control (Woosim brand, via custom native plugin) | `isConnect`, `checkConnectPrinter`, `getDevice`, `ConnectPrinter`, `PrintShoppingCard`, `PrintInvoice`, `PrintSlip` | No HTTP — calls `cordova.plugins.LogicLinkPlugin.*` (native Android AAR, Woosim SDK jars) | app-menu, checkout, claimcheck, customer-form, enquiry-detail-modal, home, payment-history, shoppingcard (+ dead pages printer, contact) |
| `RCAgentAOTProvider` (rcagent-service/rcagent-service.ts) | AOT (Airport of Thailand) e-tax receipt agent integration — custom King Power native plugin | `onLogIn`, `onCheckStatusSever`, `onNewReceipt`, `onConfirmReceipt`, `onLogOutAOT` | No HTTP — calls `cordova.plugins.RCAgentPlugin.*` (native Android AAR `RCAgent-3.1.2.A`) | checkout, customer, customer-profile, home, login, sale |
| `SunmiServiceProvider` (sunmi-service/sunmi-service.ts) | Sunmi built-in POS printer control (for Sunmi-brand terminals) | `ConnectPrinter`, `printInvoice`, `printShoppingCard`, `printSlipText` | No HTTP — calls `cordova.plugins.SunmiPlugin.*` (native, wraps `com.sunmi:printerx:1.0.15`) | login, checkout, shoppingcard |
| `ShareDataProvider` (share-data/share-data.ts) | In-memory app-session state (`userInfo`, `listBasket`, `appUpdateData`) + permission gate + misc Register/SaleEngine reads | `canDoIt` (authorization check against `userInfo.list_authorize`), `getListSubBranch`, `getPickupCodeList`, `getmPOSType` | Register `/Register/GetListSubbranch`; Sale Engine `/SaleEngine/GetPickupCodeList`, `/SaleEngine/GetmPosType` | app-menu, checkout, customer, customer-form, discount, edit-sale, flight, home, login, sale, settings, special-discount |
| `MemberProvider` (member-service-notuse/MemberProvider.ts) | Member/Loyalty domain (`getLoyaltyValue`, `getCardGroupExt`) | — | Member API `{memberApi}/api/Member/*` | **NONE — see Unused section** |
| `TokenInterceptor` / `InterceptorModule` (interceptor.ts) | Global `HttpInterceptor` — attaches `Authorization`/`CallerID` headers per URL pattern; branches for Member API (separate token), IdentityServer OAuth token endpoint (form-urlencoded, no auth header), Order Gateway API (`/api/OrderManagement/`, bearer token added by caller), and default Sale-Engine-family requests | `intercept()` | Cross-cutting — applies to every `HttpClient` call app-wide | All pages via `HttpClientModule` |

**12 active providers, 1 unused (`MemberProvider`).** Backend domains observed, matching the proposal's
named services: **Sale Engine** (SaleEngineProvider, most of AuthServiceProvider), **Register**
(`webServiceEndpoint` routes inside SaleEngineProvider/AuthServiceProvider), **Flight** (FlightProvider),
**Cash Card** (CashCardProvider), **Print Hub** (PickupServiceProvider.sendToPrinter), **Member**
(MemberProvider — unused; loyalty/carat actually reached via `SaleEngineProvider.GetCaratInformation`
instead), plus three **native-only hardware integrations with no HTTP backend**: Bluetooth/Woosim
printing (PrinterProvider), Sunmi built-in printing (SunmiServiceProvider), and AOT tax-receipt agent
(RCAgentAOTProvider).

---

## 3. Native plugins & permissions (config.xml + installed `/plugins` + AndroidManifest)

`config.xml` declares these Cordova plugins (app-wide, not page-scoped):

| Plugin | Maps to |
|---|---|
| `cordova-plugin-android-permissions` | Runtime permission requests (Bluetooth, etc.) |
| `cordova-plugin-androidx` / `-androidx-adapter` | AndroidX compat layer |
| `cordova-plugin-app-update` | In-app update check/prompt |
| `cordova-plugin-app-version` | App version display |
| `cordova-plugin-bluetooth-serial` | Bluetooth thermal printer transport |
| `cordova-plugin-device` | Device info |
| `cordova-plugin-fingerprint-aio` | Fingerprint auth (only consumed by dead `AboutPage`) |
| `cordova-plugin-ionic-webview` | WebView engine |
| `cordova-plugin-nativestorage` | (declared but app code uses `@ionic/storage` instead — see risk below) |
| `cordova-plugin-network-information` | Online/offline detection → `NoInternetPage` |
| `cordova-plugin-screen-orientation` | Orientation lock (app-level, `app.component.ts`) |
| `cordova-plugin-splashscreen` | Splash screen |
| `cordova-plugin-uniquedeviceid` | Device UUID (machine binding in Settings) |
| `cordova-plugin-whitelist` | Navigation allowlist |
| `cordova-sqlite-storage` | Storage backend for `@ionic/storage` |
| `cordova.plugin.rcagentplugin` (git-hosted, King-Power-Group/RCAgentPlugin) | AOT tax receipt agent |
| `ionic-plugin-keyboard` | Keyboard show/hide events |
| `phonegap-plugin-barcodescanner` | Barcode/QR scanning |

**Risk/finding:** the installed `/plugins` directory also contains `cordova.plugin.logiclinkplugin`
(Woosim Bluetooth printer SDK — `WoosimLib256.jar`, `woosimprinter_bt.jar`, `WoosimPrinter.jar`) and
`cordova.plugin.sunmiplugin` (wraps `com.sunmi:printerx:1.0.15`), both actively used by
`PrinterProvider`/`SunmiServiceProvider` at runtime — but **neither is declared in `config.xml`'s
`<plugin>` list**. `config.xml` has drifted from the actual installed/used plugin set. For the Flutter
rewrite this means: don't trust `config.xml` alone for the hardware-plugin list; the merged
`platforms/android/app/src/main/AndroidManifest.xml` and `/plugins` folder are the ground truth.

Actual merged Android permissions (`platforms/android/app/src/main/AndroidManifest.xml`):
`ACCESS_COARSE_LOCATION`, `ACCESS_NETWORK_STATE`, `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`,
`INTERNET`, `MOUNT_UNMOUNT_FILESYSTEMS`, `READ_EXTERNAL_STORAGE`, `READ_PHONE_STATE`,
`REQUEST_INSTALL_PACKAGES`, `USE_FINGERPRINT`, `WRITE_EXTERNAL_STORAGE`. These are the permissions the
Flutter app's `AndroidManifest.xml` will need to replicate (Bluetooth ones are the hardware-critical
ones — printer connect/scan/pair; `USE_FINGERPRINT` is legacy, tied to the dead `AboutPage` demo only).

---

## 4. Unused / Excluded

### Pages (10 of 53 — zero real inbound navigation call sites found anywhere in `src/`)

| Page | Evidence of dead status |
|---|---|
| `AboutPage` | Explicitly under `// unused page` comment in app.module.ts; no `push`/`setRoot`/`modalCtrl.create` targeting it anywhere. Ionic starter-template leftover (FingerprintAIO demo). |
| `ContactPage` | Same `// unused page` comment; zero inbound navigation. Contains dead `testPrinter()`/BarcodeScanner/BluetoothSerial demo code, superseded by the real PrinterProvider flow. |
| `TabsPage` | Only referenced in its own file and in fully-commented-out menu items in `app.component.ts` (`// { title: 'Schedule', ..., component: TabsPage ... }`). Never set as root or pushed. Ionic starter-template leftover. |
| `PromotionPage` | Only reachable as a tab of the dead `TabsPage`. No other reference. |
| `InformationPage` | Only reachable as a tab of the dead `TabsPage`. No other reference. |
| `RegistrationPage` | Imported/declared in app.module.ts only; no page or component ever navigates to it. |
| `ShoppingPage` | Imported/declared in app.module.ts only; no navigation call anywhere. |
| `ScanCustomerPage` | Has a `links` segment (`scan-customer`) and pushes `CustomerPage` from itself, but nothing ever navigates *to* it — all real references are commented out (`//this.app.getRootNav().setRoot("ScanCustomerPage", ...)` appears 3× in `customer.ts`/`customer-form.ts`, always commented). Likely superseded by the MRZ/passport-scan flow built directly into `HomePage`. |
| `PrinterPage` | Has a full `links` segment, `entryComponents` entry, and its own template — but zero inbound `push`/`modalCtrl.create` calls found anywhere in `src/`. Printer selection appears to happen implicitly inside `PrinterProvider.checkConnectPrinter()` instead of via this standalone screen. |
| `SettingByQrPage` | Imported into `settings.ts` but never referenced again in that file's body (dead import), and no other file references it. |

### Providers

| Provider | Evidence of dead status |
|---|---|
| `MemberProvider` (`src/providers/member-service-notuse/`) | Folder is literally named `-notuse`. Import and provider registration are both commented out in `app.module.ts` (`//import { MemberProvider } ...`, `//MemberProvider,`). Zero page imports it. Its two methods (`getLoyaltyValue`, `getCardGroupExt`) are dead; the equivalent loyalty/carat data is fetched via `SaleEngineProvider.GetCaratInformation` instead. |

### Other

- `FlightProvider`'s hardcoded `URL_FLIGHT = "https://api2.kingpower.com/flightapi/"` constant is declared but never referenced (all calls use `settingsProvider.settings.flightApi` instead) — dead code inside an otherwise-active provider.
- `AuthServiceProvider` contains several large commented-out method bodies (`getPassportData`, `getBoadingPass` — superseded by `getPassportByMRZ`) — dead code, safe to drop.
- Assets: no orphaned top-level asset *categories* were identified (fonts, card icons, and the four page-specific background images were all traced to at least one active page/component). A page-by-page pixel audit of every image reference was out of scope for this pass; treat the assets column above as representative, not exhaustive.

---

## 5. Summary

- **53** page classes found in `src/pages` (55 folders incl. `pages.constants.ts`, which holds no route).
- **43 ACTIVE** pages (reachable via verified real navigation calls).
- **10 ORPHANED/DEAD** pages (registered but never navigated to).
- **13** provider files in `src/providers` → **12 ACTIVE**, **1 unused** (`MemberProvider`).
- **1** global HTTP interceptor (`TokenInterceptor`) applying to all API calls.
- **19** Cordova plugins declared in `config.xml`; **2 additional** hardware plugins (LogicLink/Woosim
  printer, Sunmi printer) are installed and actively used but **not** declared in `config.xml` — a
  config drift risk for anyone relying on `config.xml` alone to enumerate native dependencies.
