# API Environment Matrix & Contract Reference: smart-pos-mobile backend services

**Every fixture in this document (sections 2+) is INFERRED FROM CLIENT CODE — NOT VERIFIED AGAINST A LIVE SERVER.
It is a stand-in for real captured request/response fixtures and MUST be confirmed against real UAT (with live
network/credential access) before being treated as ground truth for the Flutter client.** The environment
matrix in section 1 is drawn directly from the legacy app's own deploy configuration and is not an inference.

## 1. Environment matrix

Source: `smart-pos-mobile/jsonconfig/ionic.config.*.json` — 5 deploy configurations, each defining a base URL
per backend service (used as an Ionic dev-server proxy target; the same URLs are what a released build's
Settings screen would be pointed at for that environment). The legacy app does **not** bake these into the
build — every device configures its own endpoints at runtime via the Settings page (`SettingsProvider`,
persisted to `@ionic/storage`), starting from empty strings. The Flutter app's design already commits to
environment-based configuration (see `design.md`); this matrix is the source data for defining those
environments, pending confirmation of which of these remain current/approved.

| Environment | Sale Engine (`saleEngineEndpoint`) | Register (`webServiceEndpoint`) | Flight (`flightApi`) | Print Hub (`printHubEndpoint`) | Member (`memberApi`) | Cash Card (`cashCardApi`) |
|---|---|---|---|---|---|---|
| `hq-prod` (production) | `http://10.3.0.57/SaleEngineAPI/api` | `https://api2.kingpower.com/registerapi/api/` | `https://api2.kingpower.com/flightapi/api` | `http://printhub.kingpower.com` | `https://api2.kingpower.com/KPServicesAPI` | `https://api2.kingpower.com/CashCardAPI/api` |
| `hq-uat` | `https://uat-api-saleengine-hq.kingpower.com/SaleEngineAPI/api` | `https://uat-api2.kingpower.com/registerapi/api` | `https://uat-api2.kingpower.com/flightapi/api` | `http://printhub.kingpower.com` | `https://uat-api2.kingpower.com/KPServicesapi` | `https://uat-api2.kingpower.com/cashcardapi/api` |
| `one-uat` | `http://uat-api-saleengine-one.kingpower.com/SaleEngineAPI/api` | `https://uat-api2.kingpower.com/registerapi/api` | `https://uat-api2.kingpower.com/flightapi/api` | `http://printhub.kingpower.com` | `https://uat-api2.kingpower.com/KPServicesapi` | `https://uat-api2.kingpower.com/cashcardapi/api` |
| `svr-uat` | `https://uat-api-saleengine-kpi2.kingpower.com/SaleEngineAPI/api` | `https://uat-api2.kingpower.com/registerapi/api` | `https://uat-api2.kingpower.com/flightapi/api` | `http://printhub.kingpower.com` | `https://uat-api2.kingpower.com/KPServicesapi` | `https://uat-api2.kingpower.com/cashcardapi/api` |
| `hana-sit-40` (SIT, Downtown branch) | `http://10.3.8.218/SaleEngineAPIDowntown/api` | `http://10.3.8.218/registerapi/api` | `http://10.3.8.218/flightapi/api` | `http://printhub.kingpower.com` | `https://kpservices.kingpower.com/portal/developer/cashcardapi/api` *(sic — Member proxy points at a Cash Card path in this config; likely a copy-paste error in the legacy config, not a real Member endpoint)* | `https://kpservices.kingpower.com/portal/developer/cashcardapi/api` |

Notes:
- `hq-prod` is the only production environment found; the other four are UAT/SIT variants for different
  store locations/networks (HQ, "one" = One Bangkok, "svr", and a Downtown-branch SIT environment on a
  private `10.3.x.x` LAN address rather than a public domain).
- Two additional proxy paths exist per environment (`/member-profile`) pointing at
  `.../KPServices/member/details` — a REST-style member-detail lookup distinct from the `memberApi` SOAP-ish
  base above; not exercised by any active page per the API contract findings below (Member domain is dead
  code in the client), so not carried into the per-domain tables in section 2+.
- `printHubEndpoint` is identical (`http://printhub.kingpower.com`, plain HTTP) across all 5 environments —
  there is no separate UAT Print Hub target in this config set.
- Open question carried from `design.md`: whether these are still the **approved** endpoints for the Flutter
  release, or whether a newer backend API is expected — flagged there as an open question, not resolved here.

---

## 2. Auth mechanism per domain (from `src/providers/interceptor.ts`)

`TokenInterceptor.intercept()` branches on the **request URL**, not on which provider issued the call:

1. URL contains `api/Member/` → `Authorization: Bearer {Constants.AppTokenMember}` + `CallerID: {Constants.CallerIDMember}` (separate static token from the default one — Member domain only).
2. URL contains `identityserverapi/connect/token` → only `Content-Type: application/x-www-form-urlencoded` is set, no Authorization header added by the interceptor (the OAuth token endpoint call itself, for Order Gateway).
3. URL contains `/api/OrderManagement/` → **interceptor does nothing** (no headers set here); the `Authorization: Bearer {token}` header for these calls is instead set explicitly per-call in `auth-service.ts`'s `getOrderTypeApi`/`checkOrderTypeApi`/`changeOrderTypeApi` via `HttpHeaders` passed as `httpOptions`, using the OAuth token obtained via client-credentials flow.
4. **Default branch (everything else — Sale Engine, Register, Flight, Print Hub, Cash Card):** `Accept: application/json`, `Content-Type: application/json`, `Authorization: Bearer {Constants.AppToken}` (a single static bearer token baked into the app, **not** a per-user session token), `CallerID: {Constants.CallerID}`, plus `withCredentials: true`.

**Important:** the app-level bearer token in branch 4 is a static/app-wide credential (from `Constants`), separate
from the **session key** (`session_key`) obtained via `Authen/LoginAuthen` after user login. Almost every
Sale Engine/Register/Pickup/Cash Card request body also independently carries a `SessionKey`/`session_key`
field as part of its own payload — that's the actual per-user/per-terminal session identifier the *server*
uses for authorization business logic; the Bearer token is just transport-level app authentication (likely an
API-gateway/WAF check). Flight-domain calls carry neither header token variation nor SessionKey in the body
(stateless lookups). Cash Card's `checkCard` also carries no SessionKey (`CheckCardRequestModel` is just
`{ qrCode }`) — the interceptor's default Bearer token is the only auth on that call as observed in the client.

`Constants.CallerID`/`Constants.AppToken`/`Constants.AppTokenMember`/`Constants.CallerIDMember` values
themselves were not resolved (see `src/constants/constants.ts` if needed later); their existence and role are
confirmed from `interceptor.ts`, but their literal values are out of scope here.

---

## 3. Common response envelope

Nearly every Sale Engine / Register / Flight / Cash Card call returns the generic wrapper `ReturnObject<T>`
(`src/models/ReturnObject.ts`):

```ts
class ReturnObject<T> {
  isCompleted: boolean
  Data: T
  Message: Array<{ MessageType: string, MessageCode: string, MessageDesc: string }>
  totalCount: number
}
```

Confirmed client-side error-handling idiom (grepped across `checkout.ts`, `change.ts`, `voucher.ts`,
`special-discount.ts`, `cash-card.ts`, `pickup.ts`): `if (resp.isCompleted && resp.Data != null) { ...use
resp.Data... } else if (resp.Message.length > 0) { showAlert(resp.Message[0].MessageCode + ': ' +
resp.Message[0].MessageDesc) }`. This is the standard success/failure branch for essentially all
`ReturnObject<T>`-typed calls; it is **not** repeated per-operation below unless a method deviates from it.

Print Hub's `sendToPrinter` uses a different, simpler envelope, `CommonResponse`
(`src/models/CommonResponse.ts`): `{ Status: boolean, Message: string }`. Client checks `resp.Status ==
true`.

The (dead) Member-API provider uses yet another envelope, `ReturnMemberObject<T>` — same shape as
`ReturnObject<T>` but **lower-camelCase** field names: `{ isCompleted, data, message, totalCount }`.

Order Gateway's OAuth token endpoint returns `TokenRespModel`: `{ access_token, token_type, expires_in,
refresh_token, scope }` (standard OAuth2 client-credentials response, not `ReturnObject`-wrapped).

---

## 4. Domain mapping (verified against actual endpoint paths, not just provider file names)

The inventory (`inventory.md`, task 1.1) mapped domains mostly by **provider file**. Reading the actual
`this.http.get/post()` calls shows the real split is by **settings field + path prefix**, and it does not
line up 1:1 with provider files. Corrections vs. `inventory.md`:

| Domain (proposal name) | Settings field(s) used as base URL | Path prefix(es) | Provider file(s) it's actually called from |
|---|---|---|---|
| **Sale Engine** | `saleEngineEndpoint` | `/SaleEngine/*`, `/Authen/*`, `/Pickup/*` (see note) | `sale-engine.ts` (bulk), `auth-service.ts` (Authen family + duplicate `getConfigPos`), `pickup-service.ts` (`getPickingList`/`createPickingList`), `share-data.ts` (`getPickupCodeList`, `getmPOSType` — these take a `url` param, normally set to `saleEngineEndpoint` by the caller) |
| **Register** | `webServiceEndpoint` (mostly), `saleEngineEndpoint` (one conditional branch) | `/Register/*` | `sale-engine.ts` (`getShippingAddress`, `getCustomerInfo`, `regsiter`, `getNationality`), `FlightProvider.ts` (`getCustomerInfo` — a duplicate of the one in `sale-engine.ts`), `share-data.ts` (`getListSubBranch`, takes `url` param) |
| **Flight** | `flightApi` | `/flight/*` | `FlightProvider.ts` only |
| **Print Hub** | `printHubEndpoint` | `/Printer/*` | `pickup-service.ts` (`sendToPrinter` only) |
| **Member** | `memberApi` | `/api/Member/*` | `MemberProvider.ts` — **entire provider is dead code** (folder literally named `member-service-notuse`, commented out of `app.module.ts`). No active page calls it. The functional equivalent used in production is `SaleEngineProvider.GetCaratInformation`, which is physically a **Sale Engine** endpoint (`{saleEngineEndpoint}/SaleEngine/GetCaratInformation`), not a Member-API call. Both are documented below. |
| **Cash Card** | `cashCardApi` | `/CashCard/*` | `CashCardProvider.ts` only |
| *(not one of the 6 — auxiliary)* **Order Gateway** | dynamic URL fetched at runtime via `getConfigPos(["OrderGatewayAPI", ...])`, OAuth via `AccessTokenURL` | `/api/OrderManagement/*` | `auth-service.ts` (`getOrderTypeApi`/`checkOrderTypeApi`/`changeOrderTypeApi`, `getOAuthToken`). Kept in this doc because it lives inside `AuthServiceProvider` and the interceptor has a dedicated branch for it, but it is **not** one of the 6 named domains. |

**Note on `/Pickup/*`:** `getPickingList` and `createPickingList` hit `saleEngineEndpoint` (the Sale Engine
base URL) but with a `/Pickup/` path prefix instead of `/SaleEngine/`. `inventory.md` filed these under
"Print Hub domain" via the provider name (`PickupServiceProvider`); this doc splits them: `getPickingList` /
`createPickingList` → **Sale Engine** domain (same base URL, sibling path family), `sendToPrinter` → **Print
Hub** domain (genuinely different base URL, `printHubEndpoint`).

---

## 5. Sale Engine domain — 53 operations

Base URL: `{saleEngineEndpoint}`. All POST. Envelope: `ReturnObject<T>` unless noted.

### 5a. Authen family (from `auth-service.ts`)

| # | Method | Verb + Path | Auth | Request (illustrative) | Response (illustrative) | Error/edge handling |
|---|---|---|---|---|---|---|
| 1 | `authservice.login` | `POST /Authen/LoginAuthen` | Interceptor default Bearer + CallerID | `{"user_code":"U001","user_password":"pass123","branch_no":"03","module_code":"MposKpi","machine_ip":"01afaa68-f583-9816-2868-591032116435"}` (all required; `machine_ip` falls back to a hardcoded UUID if `settings.uuid` is empty) | `ReturnObject<LoginResult>` → `Data: {session_key, dateTimeServer, currDateTime, userInfo: {branch_no, user_code, user_name, MachineEnv: {...EnvModel}, list_authorize: [{ModuleCode,AuthCode,Action}]}}` | Login page checks `resp.Data.session_key != ""` (not `isCompleted`) to decide success — deviates from the standard idiom; empty/invalid creds just yield an empty `session_key`, no `Message` array checked here. |
| 2 | `authservice.GetEnvMachineRealTime` | `POST /Authen/GetEnvMachineData` | Interceptor default | `{"branchNo":"03","machineIP":"01afaa68-..."}` | `ReturnObject<EnvModel>` → `Data: {MachineIP, MachineNo, MachineName, posType, buylimitHour, site, RcURL, concession_code, request_RC, ClientId, ClientSecret, ...}` | Standard `isCompleted`/`Message` idiom (inferred). |
| 3 | `authservice.RCRequest` | `POST /Authen/RCRequest` | Interceptor default | `{"machineNo":"M001","branchNo":"03"}` | `ReturnObject<RCRequest>` → `Data: {TaxAbbNo, Recipt, request_RC}` | Standard idiom (inferred). |
| 4 | `authservice.getHasPermission` | `POST /Authen/HasPermission` | Interceptor default | `LoginResult` shell with only `session_key` populated: `{"session_key":"abc123"}` | `ReturnObject<UserInfoModel>` → `Data: {branch_no, user_code, user_name, MachineEnv, list_authorize}` | Called internally by `getEnvironment()`; result's `.Data` resolved directly with no error branch observed. |
| 5 | `authservice.logout` | `POST /SaleEngine/SignOut` | Interceptor default | `{"SessionKey":"abc123"}` | `ReturnObject<boolean>` | Standard idiom (inferred). Path is `/SaleEngine/SignOut` despite living in `AuthServiceProvider` — Sale Engine domain, not a separate Authen endpoint. |
| 6 | `authservice.getConfigPos` | `POST /SaleEngine/GetConfigPos` | Interceptor default | Body is a bare string array: `["AccessTokenURL","ClientID","ClientSecret","Scope","OrderGatewayAPI"]` | `ReturnObject<Array<ConfigPosModel>>` → `Data: [{code:"AccessTokenURL",value:"https://..."},...]` | Caller does `data.Data.find(item => item.code == "X").value` — **throws if the requested code is absent from the response**; duplicate of `SaleEngineProvider.getConfigPos` (#43 below), same endpoint, two call sites. |
| 7 | `authservice.getOAuthToken` | `POST {accessTokenApi}` (URL is itself a value returned by op #6) | Only `Content-Type: application/x-www-form-urlencoded` force-set; no bearer token on this call itself | Body is form-urlencoded: `client_id=X&client_secret=Y&scope=Z&grant_type=client_credentials` | `TokenRespModel`: `{access_token, token_type, expires_in, refresh_token, scope}` | Not currently invoked live — `checkOrderType`/`changeOrderType`/`getOrderType` call the Order Gateway API with an empty-string token instead (dead/commented call sites). **Defined-but-unreachable in current app flow.** |

### 5b. Order/Cart/Payment/Promotion/Enquiry family (from `sale-engine.ts`, unless noted)

| # | Method | Verb + Path | Auth | Request (illustrative) | Response (illustrative) | Error/edge handling |
|---|---|---|---|---|---|---|
| 8 | `saleEngine.getOrder` | `POST /SaleEngine/GetOrder` | Interceptor default | `GetOrderContract`: `{"SessionKey":"abc123","Attributes":[{"Group":"BASKET","Code":"shoppingCard","ValueOfString":"CPX0001"}]}` | `ReturnObject<OrderClass[]>` → `Data: [{Guid, OrderDetails:[...], OrderPayments:[...], BillingAmount:{...}, TotalBillingAmount:{...}, isCheckOut, ...}]` — see `OrderClass` in `OrderClass.ts` for the full shape | Standard idiom. |
| 9 | `saleEngine.addItemToOrder` | `POST /SaleEngine/AddItemToOrder` | Interceptor default | `OrderAddContract`: `{"ItemCode":"ART001","ItemGWP":"","SessionKey":"abc123","Rows":["1"]}` | `ReturnObject<OrderClass[]>` | Standard idiom. |
| 10 | `saleEngine.actionItemToOrder` | `POST /SaleEngine/ActionItemToOrder` | Interceptor default | `{"ActionItemValues":[{"Action":"change_qty","Value":"2"}],"Row":"1","SessionKey":"abc123"}` (`Action` from `ActionToOrderCommand` enum) | `ReturnObject<OrderClass[]>` | Standard idiom. |
| 11 | `saleEngine.actionListItemToOrder` | `POST /SaleEngine/ActionListItemToOrder` | Interceptor default | `{"ActionItemValue":{"Action":"delete","Value":""},"Rows":["1","2"],"SessionKey":"abc123"}` | `ReturnObject<OrderClass[]>` | Standard idiom. |
| 12 | `saleEngine.saveOrder` | `POST /SaleEngine/SaveOrder` | Interceptor default | `GetOrderContract` (same shape as #8) | `ReturnObject<OrderClass[]>` | Standard idiom. |
| 13 | `saleEngine.getCurrency` | `POST /SaleEngine/GetCurrency` | Interceptor default | `{"branch_no":"03"}` | `ReturnObject<CurrencyModel[]>` → `Data: [{branch_no,curr_code:"USD",curr_desc,curr_rate:35.5,curr_short:"$"}]` | Standard idiom. |
| 14 | `saleEngine.getPaymentMethodList` | `POST /SaleEngine/GetPaymentMethod` | Interceptor default | `{}` (empty body) | `ReturnObject<PaymentMethodResult[]>` → `Data: [{method_code:"03",method_desc:"VISA",method_short,is_cashcard,is_voucher,...}]` | Standard idiom. |
| 15 | `saleEngine.getWalletTypeFromBarcode` | `POST /SaleEngine/GetWalletTypeFromBarcode` | Interceptor default | `{"barcode":"280...","machine_ip":"...","branch_no":"03","prefix":"LP"}` | `ReturnObject<WalletTypeResultModel>` → `Data: {method_code,wallet_type,barcode_prefix,walletagent_master:{wallet_agent,partnertype_id,merchant_id,wsurl}}` | Standard idiom. |
| 16 | `saleEngine.addOrderPayment` | `POST /SaleEngine/AddOrderPayment` | Interceptor default | `AddOrderPaymentParameter`: `{"OrderGuid":"guid","Payment":{...OrderPayment},"SessionKey":"abc123"}` | `ReturnObject<OrderClass[]>` | Standard idiom. |
| 17 | `saleEngine.checkOutPaymentOrder` | `POST /SaleEngine/CheckOutPaymentOrder` | Interceptor default | `CheckOutPaymentOrderParam`: `{"OrderGuid":"guid","SessionKey":"abc123"}` | `ReturnObject<OrderClass[]>` | **Grep-verified** (`checkout.ts:3425`): `if (!data.isCompleted && data.Message.length > 0) alert(data.Message[0].MessageCode + data.Message[0].MessageDesc)`. |
| 18 | `saleEngine.addPaymentToOrder` | `POST /SaleEngine/AddPaymentToOrder` | Interceptor default | Same shape as `AddOrderPaymentParameter` (#16) | `ReturnObject<OrderClass[]>` | Standard idiom. |
| 19 | `saleEngine.actionOrderPayment` | `POST /SaleEngine/ActionOrderPayment` | Interceptor default | `ActionOrderPaymentParameter`: `{"OrderGuid":"guid","Rows":["1"],"Action":"take_collect","Value":"","currency":"THB","prefix":"","SessionKey":"abc123"}` | `ReturnObject<OrderClass[]>` | **Grep-verified** (`change.ts:172`, `special-discount.ts`): same `isCompleted`/`Message[0]` idiom; `special-discount.ts:175` reads `resp.Data[0]`. |
| 20 | `saleEngine.actionPaymentToOrder` | `POST /SaleEngine/ActionPaymentToOrder` | Interceptor default | Same shape as #19 | `ReturnObject<OrderClass[]>` | Standard idiom (inferred). |
| 21 | `saleEngine.getShoppingInfo` | `POST /SaleEngine/ShoppingInfo` | Interceptor default | `data: any` — **client sends an untyped payload** | `ReturnObject<ShoppingInfo>` → `Data: {isLock:boolean, machine:string, privilege?:string}` | Request shape UNKNOWN; response is typed. |
| 22 | `saleEngine.getPromotionList` | `POST /SaleEngine/GetPromotionList` | Interceptor default | `PromotionContractModel`: `{"session_key":"abc123","branch_no":"03","subbranch_code":"CPX-DT","promo_code":"","excludeMember":false}` | `ReturnObject<Array<PromotionViewModel>>` → `Data: [{promo_code,promo_name,notallow_SMC,allowOverWriteDISC,discAmt,discRate}]` | Standard idiom. |
| 23 | `saleEngine.getPromotion` | `POST /SaleEngine/GetPromotion` | Interceptor default | Same `PromotionContractModel` shape as #22 | `ReturnObject<PromotionViewModel>` (single object) | Standard idiom. |
| 24 | `saleEngine.validateGWP` | `POST /SaleEngine/ValidateGWP` | Interceptor default | `CheckOutPaymentOrderParam`: `{"OrderGuid":"guid","SessionKey":"abc123"}` | `ReturnObject<OrderClass[]>` | **Grep-verified** (`checkout.ts:2130`): `if (resp.isCompleted == true) savePaymentV2(); else if (!resp.isCompleted && resp.Message.length > 0) { ...show error... }`. |
| 25 | `saleEngine.ValidatePromotionMember` | `POST /SaleEngine/ValidatePromotionMember` | Interceptor default | `{"promoCode":"PROMO1","SessionKey":"abc123"}` | `ReturnObject<number>` — bare number, business meaning not evident from client | Standard idiom (inferred). |
| 26 | `saleEngine.finishPaymentOrder` | `POST /SaleEngine/FinishPaymentOrder` | Interceptor default | `CheckOutPaymentOrderParam` shape (`OrderGuid`, `SessionKey`) — a richer `FinishPaymentOrderParameter` model exists but isn't actually used as this method's param type, likely model/call-site drift | `ReturnObject<OrderClass[]>` | Standard idiom (inferred). |
| 27 | `saleEngine.getPromotionQr` | `POST /SaleEngine/GetPromotionByQRCode` | Interceptor default | `ScanPromotionQrContract`: `{"SessionKey":"abc123","qrCodeJson":"{...raw scanned QR JSON string...}"}` | `ReturnObject<ValueAdjust>` → `Data: {Guid,Type,FieldName,VADetail:{Code,Desc},Amount:{...AmountModel},Percent,IsPercent,RefNo,typeDiscount}` | Standard idiom (inferred). |
| 28 | `saleEngine.printTaxInvoice` | `POST /SaleEngine/PrintTaxInvoice` | Interceptor default | `PrintInvoiceParam`: `{"OrderNo":"12345","ClaimcheckNo":"CC001","RCCode":"","SessionKey":"abc123","Mode":""}` | `ReturnObject<PrintInvoiceResponse[]>` → `Data: [{Type:"...", Data:{Copy:[{type,value}], Original:[...], Confirm:[...]}}]` — print-ready document payload | Standard idiom (inferred). |
| 29 | `saleEngine.exchangeCurrency` | `POST /SaleEngine/ExchangeCurrency` | Interceptor default | `ExchangeCurrencyParam`: `{"currCode":"USD","currAmount":100,"basecurrAmount":0,"isPaid":false,"isChangeButton":true}` | `ReturnObject<AmountModel>` → `Data: {CurrCode:{Code,Desc},CurrRate,CurrAmt,BaseCurrCode:{...},BaseCurrRate,BaseCurrAmt,totalChange,curChange}` | Standard idiom (inferred). |
| 30 | `saleEngine.getBankOfEDCList` | `POST /SaleEngine/GetBankOfEDCList` | Interceptor default | `data: any` — **untyped request** | `ReturnObject<BankModel[]>` → `Data: [{bank_code:"004",bank_name:"KBANK",remark}]` | Request shape UNKNOWN. |
| 31 | `saleEngine.updateOrderStatus` | `POST /SaleEngine/UpdateOrderStatus` | Interceptor default | `UpdateOrderStatusModel`: `{"branchNo":"03","shoppingCard":"CPX0001","orderStatus":"e","SessionKey":"abc123","orderNo":"12345"}` (`orderStatus` enum: `a`=Lock,`A`=Unlock,`e`=Checkout,`E`=End) | `ReturnObject<OrderClass[]>` | Standard idiom (inferred). |
| 32 | `saleEngine.getListAgent` | `POST /SaleEngine/GetListAgent` | Interceptor default | `AgentParam`: `{"branchNo":"03","input":"AG","typeSearch":"agent"}` | `ReturnObject<AgentModel[]>` → `Data: [{SubAgentCode,SubAgentDesc,AgentCode,AgentDesc,CustomerType,CustomerTypeDesc}]` | Standard idiom (inferred). Shared by 3 picker pages. |
| 33 | `saleEngine.clearSession` | `POST /SaleEngine/ClearSession` | Interceptor default | `ClearSessionParam`: `{"sessionKey":"abc123","action":"clear"}` | `ReturnObject<boolean>` | Standard idiom (inferred). |
| 34 | `saleEngine.sendEmail` | `POST /SaleEngine/SendEmail` | Interceptor default | `SendEmailParamModel`: `{"branchNo":"03","shoppingCard":"CPX0001","isMember":false}` | `ReturnObject<SendEmailOutputModel>` → `Data: {Email:"cust@example.com", isSendMail:true}` | Standard idiom (inferred). |
| 35 | `saleEngine.getOrderList` | `POST /SaleEngine/GetOrderList` | Interceptor default | `GetEnquiryContract` (extends `GetOrderContract`): `{"SessionKey":"abc123","Attributes":[],"paging":{"pageNo":0,"pageSize":20},"filter":[{"element":"OrderDate","option":"ne","low":"2026-01-01","high":"2026-01-31"}],"sorting":[{"sortBy":"CreateDate","orderBy":"desc"}]}` | `ReturnObject<OrderClass[]>` (paginated) | Standard idiom (inferred). |
| 36 | `saleEngine.getDateTimeServer` | `POST /SaleEngine/GetDateTimeServer` | Interceptor default | `{}` | `ReturnObject<Date>` → `Data: "2026-08-18T10:00:00Z"` | Standard idiom (inferred). |
| 37 | `saleEngine.findPaymentHistory` | `POST /SaleEngine/FindPaymentHistory` | Interceptor default | `PaymentHistoryParamModel`: `{"OrderGuid":"guid","All":false,"SessionKey":"abc123"}` | `ReturnObject<OrderClass[]>` | Standard idiom (inferred). |
| 38 | `saleEngine.refundOrderPayment` | `POST /SaleEngine/RefundOrderPayment` | Interceptor default | `RefundOrderPaymentParamModel`: `{"OrderGuid":"guid","refunedType":1,"SessionKey":"abc123"}` (enum: 1=RefundOrder,2=RefundWallet,3=RefundAll) | `ReturnObject<OrderClass[]>` | Standard idiom (inferred). |
| 39 | `saleEngine.SaveSignature` | `POST /SaleEngine/SaveSignature` | Interceptor default | `data: any` — **untyped request**; plausible shape from sibling models: `{"sessionKey":"abc123","branch_no":"03","shoppingCard":"CPX0001","order_no":12345,"orderSignatures":[{"code":"1","value":"<base64 png>"}]}` | `ReturnObject<OrderSignatureModel[]>` → `Data: [{code,value}]` | Request shape not enforced by provider — illustrative body is a best-effort guess, not confirmed. |
| 40 | `saleEngine.reverseVirtualStock` | `POST /SaleEngine/ReverseVirtualStock` | Interceptor default | `ReverseVirtualStockModel`: `{"SessionKey":"abc123"}` | `ReturnObject<Boolean>` | Standard idiom (inferred). |
| 41 | `saleEngine.addVoucher` | `POST /SaleEngine/AddVoucher` | Interceptor default | `VoucherParamModel`: `{"session_key":"abc123","methodCode":"VOUCHER","barcode":"V0001","amount":100,"typeVoucher":"fix"}` | `ReturnObject<OrderClass>` (single object) | **Grep-verified** (`voucher.ts:192`): `if (resp.isCompleted && resp.Data != null) { order = resp.Data; find matching voucher in resp.Data.Voucher[] } else { alert(...) }`. |
| 42 | `saleEngine.updateShippingAddress` | `POST /SaleEngine/UpdateShippingAddress` | Interceptor default | `UpdateShipAddressParameter`: `{"ShipAddress":"123 Main St","SessionKey":"abc123"}` | `ReturnObject<OrderClass[]>` | Standard idiom (inferred). Sibling read op `getShippingAddress` is a **Register**-domain call. |
| 43 | `saleEngine.getConfigPos` | `POST /SaleEngine/GetConfigPos` | Interceptor default | Same as auth-service's #6: bare `string[]` of config codes | `ReturnObject<Array<ConfigPosModel>>` | Duplicate of op #6 (same endpoint, defined on both providers). |
| 44 | `saleEngine.getmPOSType` | `POST /SaleEngine/GetmPosType` | Interceptor default | `{}` | `ReturnObject<string>` → `Data: "Sale"` | Standard idiom (inferred). Duplicate exists on `ShareDataProvider` (op #53). |
| 45 | `saleEngine.getPromoterDFA` | `POST /SaleEngine/PromoterDFA` | Interceptor default | `UserInputModel`: `{"branchNo":"03","input":"U0","typeSearch":"user","machineNo":"01afaa68-..."}` | `ReturnObject<OutputUserByOperatorModel[]>` → `Data: [{userCode,userName}]` | Standard idiom (inferred). |
| 46 | `saleEngine.SaveUpdateRCode` | `POST /SaleEngine/UpdateRCode` | Interceptor default | `SaveUpdateRcCodeModel`: `{"session_key":"abc123","rcCode":"RC001"}` | `ReturnObject<boolean>` | Standard idiom (inferred). |
| 47 | `saleEngine.GetMasterByBarcodeDLL` | `POST /SaleEngine/GetMasterByBarcodeDLL` | Interceptor default | `MasterArticleDTI`: `{"siteCode":"CPX","barcode":"880...","priceDate":"2026-08-18"}` | `ReturnObject<ArticleResp>` → `Data: {Article: {ArticleCode,ArticleName,EANCode,Brand:{Code,Name},MCDetail:{...},VatRate,Price,VASs:[...],Promotions:[...],...}}` | Standard idiom (inferred). |
| 48 | `saleEngine.GetCaratInformation` | `POST /SaleEngine/GetCaratInformation` | Interceptor default | `data: any` — **untyped request**, plausibly a member/card identifier | `ReturnObject<CaratReponse>` → `Data: {availiableAmount, availiableQuota, burnRate}` | Request shape UNKNOWN. **This is the operational replacement for the dead `MemberProvider.getLoyaltyValue`** — see §8. |
| 49 | `saleEngine.ActionCouponInOrder` | `POST /SaleEngine/ActionCouponInOrder` | Interceptor default | `CouponInOrderRequest`: `{"SessionKey":"abc123","CouponCode":"CPN001","Action":"apply"}` | `ReturnObject<Array<CouponInOrderReponse>>` → `Data: [{PromotionCode,PromotionName,SapPromoCode,EligibleSkus:[],TypeCode,Value,MaxAmountPerBill,...}]` | Standard idiom (inferred). |

### 5c. Pickup-adjacent, same base URL (from `pickup-service.ts`)

| # | Method | Verb + Path | Auth | Request | Response | Error handling |
|---|---|---|---|---|---|---|
| 50 | `pickupService.getPickingList` | `POST /Pickup/GetPickingList` | Interceptor default | `PickupQueryContract` (extends `GetEnquiryContract`): `{"session_key":"abc123","branchNo":"03","shoppingCard":"CPX0001","flightCode":"TG101","pickupCode":"A1","isShowAll":false,"paging":{"pageNo":0,"pageSize":20},"filter":[],"sorting":[]}` | `ReturnObject<PickupHeaderModel>` → `Data: {shoppingCard,name,passport,totalOrder,totalTransit,listdetail:[{recNo,orderNo,pickupCode,status,numberStatus,listItem:[...]}],counterlistdetail:[...],flightlistdetail:[...]}` | **Grep-verified** (`pickup.ts:207`): iterates `resp.Data.listdetail`, switches on `item.numberStatus` (enum `PickupDetailStatusEnum`); checks `resp.Data != null` rather than `isCompleted`. |
| 51 | `pickupService.createPickingList` | `POST /Pickup/CreatePickingList` | Interceptor default | `CreatePickingListModel`: `{"session_key":"abc123","listClaimCheck":[{"recNo":"REC001","branchNo":"03"}],"comCode":"KP","pickupCode":"A1"}` | `ReturnObject<PrinterPickupResult>` → `Data: {Printers:[{PrinterIP,PrinterCode,PrinterName,ConnectionGuid}], PickingList:{PickupNo,ShoppingCard,CustomerName,FlightNo,Data:[{PackingNo,OrderDate,HangingNo}]}}` | **Grep-verified** (`pickup.ts:592`): standard idiom; on success passes `resp.Data` to `sendToPrintHub()` (§6 op #1). |
| 52 | `shareData.getPickupCodeList` | `POST /SaleEngine/GetPickupCodeList` | Interceptor default | `{}` (base URL passed in as `url` param, normally `settings.saleEngineEndpoint`) | `ReturnObject<Array<MasterPickupCode>>` → `Data: [{pickupCode,pickupName,pickupDisplay}]` | If `url == ""`, client short-circuits locally and returns an empty envelope **without making an HTTP call**. |
| 53 | `shareData.getmPOSType` | `POST /SaleEngine/GetmPosType` | Interceptor default | `{}` (`url` param) | `ReturnObject<string>` | Same local empty-`url` guard. Duplicate of op #44. |

**Sale Engine domain total: 53 operations** (§5a=7, §5b=42, §5c=4).

---

## 6. Register domain — 7 call sites, 6 unique endpoints

Base URL: `{webServiceEndpoint}` (mostly); `getCustomerInfo` can alternatively hit `{saleEngineEndpoint}`
depending on a client-side `isMPOSAirport` flag, keeping the `/Register/` path either way. All POST.
Envelope: `ReturnObject<T>`.

| # | Method | Verb + Path | Auth | Request | Response | Error handling |
|---|---|---|---|---|---|---|
| 1 | `saleEngine.getShippingAddress` | `POST /Register/GetShippingBySessionID?sessionID={sessionID}` | Interceptor default | Session ID as a **query string param**, empty JSON body `{}` | `ReturnObject<string>` → `Data: "123 Main St, Bangkok"` | Standard idiom (inferred). Only Register-domain call using a query param for its key identifier. |
| 2 | `saleEngine.getCustomerInfo` (duplicated verbatim on `FlightProvider`) | `POST /Register/GetCustomer` — base URL `saleEngineEndpoint` if `isMPOSAirport==true`, else `webServiceEndpoint` | Interceptor default | `CustomerContractModel`: `{"branchNo":"03","SubBranch":"CPX-DT","shoppingCard":"CPX0001","isTour":false,"pickupCode":"A1","machineNo":"01afaa68-..."}` | `ReturnObject<Array<CustomerModel>>` → `Data: [{action,isFound,person:{englishName,passportNo,nationality,listContact:[...],listPrivilege:[...],listWalletMember:[...]},tour:{...},agentCode,isMember}]` | Standard idiom (inferred). **Duplicated across two providers** with identical signature/endpoint — a code-cleanup item for the migration. |
| 3 | `saleEngine.regsiter` (sic — typo preserved from source) | `POST /Register/RegisterAPI` | Interceptor default | `Array<RegisterParamModel>`: `[{"agentCode":"AG1","subAgentCode":"","subBranchCode":"CPX-DT","branchNo":"03","platformCode":"MPOS","prefixShoppingCard":"CPX","userCode":"U001","machineNo":"01afaa68-...","action":"register","allowTakeAway":true,"isAirport":true,"tour":{...},"listPersonal":[{...PersonInfo}]}]` — request body is a bare **array** | `ReturnObject<Array<RegisterResponse>>` → `Data: [{listOutput:[{runningNo,shoppingCard,qrShoppingCard,listCoupon:[{couponCode,couponDetail,couponQRCode}]}],listMessage,isComplete}]` | Standard idiom (inferred); note `RegisterResponse.isComplete` is a *nested* flag distinct from the envelope's `isCompleted`. |
| 4 | `saleEngine.getNationality` | `POST /Register/GetNationality` | Interceptor default | `NationalParamModel`: `{"countryCode":"","pageNo":0,"pageSize":50}` | `ReturnObject<Array<NationalOutputModel>>` → `Data: [{CountryCode:"THA",CountryName:"Thailand"}]` | Standard idiom (inferred). |
| 5 | `flightProvider.getCustomerInfo` | `POST /Register/GetCustomer` | Interceptor default | Same `CustomerContractModel` shape as op #2 | Same shape as op #2 | Duplicate of op #2. |
| 6 | `shareData.getListSubBranch` | `POST /Register/GetListSubbranch` | Interceptor default | `GetListSubBranchContract`: `{"key":"","pageNo":0,"pageSize":50}` (`url` param, normally `webServiceEndpoint`) | `ReturnObject<Array<SubBranchModel>>` → `Data: [{subbranchCode:"CPX-DT",subbranchName,BranchNo:"03",ConfigSC,CutOffTime}]` | Local empty-`url` guard, same as Sale Engine §5c ops #52/#53. |

**Register domain total: 6 unique endpoints, 7 call sites** (op #2/#5 are the same endpoint from two providers).

---

## 7. Flight domain — 3 operations

Base URL: `{flightApi}`. All POST. Envelope: `ReturnObject<T>`. Provider: `FlightProvider.ts` exclusively for
these three (its 4th method, `getCustomerInfo`, is Register domain — already counted in §6).

A dead constant `URL_FLIGHT = "https://api2.kingpower.com/flightapi/"` exists in this file but is never used —
all three live methods use `settingsProvider.settings.flightApi` instead.

| # | Method | Verb + Path | Auth | Request | Response | Error handling |
|---|---|---|---|---|---|---|
| 1 | `flightProvider.getFlightByCode` | `POST /flight/GetFlightByCode` | Interceptor default (no Flight-specific auth branch) | `FlightParamModel`: `{"flightCode":"TG101","subBranchCode":"CPX-DT","flightType":"arrival","isAirport":true,"pageNo":0,"pageSize":20}` | `ReturnObject<FlightClass[]>` → `Data: [{flightCode,flightDescription,ArrDepAirportName,DestAirportName,flightType,airlineCode,flightNo,flightDate}]` | Standard idiom (inferred). |
| 2 | `flightProvider.getDateByFlight` | `POST /flight/getDateByFlight` (lower-case `g`, inconsistent vs. siblings) | Interceptor default | Same `FlightParamModel` shape as op #1 | Same shape as op #1 | Standard idiom (inferred). |
| 3 | `flightProvider.validateFlight` | `POST /flight/ValidateFlight` | Interceptor default | `ValidateFlightParamModel`: `{"flightCode":"TG101","flightDateTime":"2026-08-18T14:30:00"}` | `ReturnObject<ValidateFlightReturn>` → `Data: {flightValidate:true,pickupCode:"A1",pickupName:"Counter A1",puImageUrl:"https://.../a1.png"}` | Standard idiom (inferred). |

**Flight domain total: 3 operations.**

---

## 8. Print Hub domain — 1 operation

Base URL: `{printHubEndpoint}`. Provider: `pickup-service.ts` (its only true Print Hub call — see §4 note).

| # | Method | Verb + Path | Auth | Request | Response | Error handling |
|---|---|---|---|---|---|---|
| 1 | `pickupService.sendToPrinter` | `POST /Printer/PrintPickupDocument` | Interceptor default (no Print-Hub-specific branch) | `PickupPrintModel`: `{"HubConnectionId":"guid-from-signalr-or-similar","PrinterName":"COUNTER-A1-PRN","Data":{"PickupNo":"PU001","ShoppingCard":"CPX0001","CustomerName":"John Doe","FlightNo":"TG101","FlightDateTime":"2026-08-18T14:30:00","CounterNo":"A1","TotalPack":"2","Data":[{"PackingNo":"PK001","OrderDate":"2026-08-18","HangingNo":"H001"}]}}` — `HubConnectionId` strongly suggests this print job is routed via a **SignalR hub connection ID** obtained elsewhere (its origin was not located in this pass — flagged as a gap) | `CommonResponse` (different envelope): `{"Status":true,"Message":"Print job queued"}` | **Grep-verified** (`pickup.ts:360`): `if (resp.Status == true) { showSuccessAlert() }` — no failure branch observed at this call site. |

**Print Hub domain total: 1 operation.**

---

## 9. Cash Card domain — 1 operation

Base URL: `{cashCardApi}`. Provider: `CashCardProvider.ts` — the entire provider is one method.

| # | Method | Verb + Path | Auth | Request | Response | Error handling |
|---|---|---|---|---|---|---|
| 1 | `cashCardProvider.checkCard` | `POST /CashCard/CheckCard` | Interceptor default (a commented-out CashCard-specific Bearer/CallerID exists in the provider file but is dead — the live call goes through the default branch) | `CheckCardRequestModel`: `{"qrCode":"8801234567890"}` — the only field sent; no `SessionKey` | `ReturnObject<CheckCardResponseModel>` → `Data: {cashCardId,cashCardNo,cardType:"CashCard",validDate,expireDate,balance:1500.00}` | **Grep-verified** (`cash-card.ts:231`, `checkout.ts:3255`): standard `isCompleted && resp.Data != null` idiom; reads `resp.Data.cardType` to branch UI. |

**Cash Card domain total: 1 operation.**

---

## 10. Member domain — 2 operations (entire provider DEAD CODE) + 1 bridge operation

Base URL: `{memberApi}`. Provider: `MemberProvider.ts` (folder name `member-service-notuse`). **Not wired into
the app** — import/DI registration commented out in `app.module.ts`; no active page injects it. Documented
because Member is one of the 6 named domains, and because these are the only endpoints using the
Member-specific auth header.

| # | Method | Verb + Path | Auth | Request | Response | Error handling |
|---|---|---|---|---|---|---|
| 1 | `memberProvider.getLoyaltyValue` | `POST /api/Member/GetLoyaltyValue` | **Member-specific branch**: `Authorization: Bearer {Constants.AppTokenMember}`, `CallerID: {Constants.CallerIDMember}` | `LoyaltyParam`: `{"element":"MID","low":"1234567890","lvFilter":2}` (`lvFilter` enum: 0=NonCorporate,1=Corporate,2=All) | `ReturnMemberObject<LoyaltyValueReponse>` (**lower-camelCase envelope**: `isCompleted`, `data`, `message`, `totalCount`) → `data: {totalAccumulateCarat,totalCarat,totalEpurse,nextTier:{currentCardType:{...},nextCardType:{...},accumulateSale},listOfLoyaltyData:[{lvType,lvCode,lvName,lvValue,validDate,expireDate}]}` | No call sites exist (dead provider). |
| 2 | `memberProvider.getCardGroupExt` | `POST /api/Member/GetCardGroupExt` | Same Member-specific branch | `CardGroupParam`: `{"element":"MID","low":"1234567890"}` | `ReturnMemberObject<Array<CardGroupReponse>>` → `data: [{groupCode,attributes:[{code,value}]}]` | No call sites exist (dead provider). |
| 3 (bridge, cross-listed) | `saleEngine.GetCaratInformation` | `POST {saleEngineEndpoint}/SaleEngine/GetCaratInformation` | Interceptor default (Sale Engine's static Bearer, not the Member-specific token) | `data: any` — UNKNOWN | `ReturnObject<CaratReponse>` → `Data: {availiableAmount,availiableQuota,burnRate}` | Same as Sale Engine §5b op #48 — the *actual* loyalty/carat data source in production, physically on Sale Engine. **Flutter migration should treat this as the real Member-equivalent read**, not the dead `MemberProvider` endpoints. |

**Member domain total: 2 defined-but-dead operations** (+ 1 already counted under Sale Engine, cross-referenced).

---

## 11. Auxiliary — Order Gateway (not one of the 6 named domains)

Included for completeness since it lives inside `AuthServiceProvider` with its own interceptor branch, but
**not counted in the 6-domain totals**.

| # | Method | Verb + Path | Auth | Request | Response | Error handling |
|---|---|---|---|---|---|---|
| 1 | `authservice.getOrderTypeApi` | `POST {urlApi}/api/OrderManagement/GetOrderType` (`urlApi` resolved at runtime from `getConfigPos(["OrderGatewayAPI"])`) | Explicit `Authorization: Bearer {token}` set by the calling method, not the interceptor | `OrderTypeModel`: `{"branchNo":"03","shoppingCard":"CPX0001","orderNo":12345,"orderType":"","actType":1,"user":"U001"}` | `ReturnObject<string>` → `Data: "L"` (order-type code) | Live call sites pass `token=""` — the OAuth token-acquisition step (§5a op #7) is dead/commented-out; **the live app currently calls this endpoint with no bearer token at all** despite the client-credentials plumbing existing. Flag explicitly for the Flutter team. |
| 2 | `authservice.checkOrderTypeApi` | `POST {urlApi}/api/OrderManagement/CheckOrderType` | Same as op #1 (empty-string token in practice) | Same `OrderTypeModel` shape | Same shape as op #1 | Same empty-token discrepancy. |
| 3 | `authservice.changeOrderTypeApi` | `POST {urlApi}/api/OrderManagement/ChangeOrderType` | Same as op #1 (empty-string token in practice) | Same `OrderTypeModel` shape | Same shape as op #1 | Same empty-token discrepancy. |
| 4 | `authservice.getOAuthToken` | `POST {accessTokenApi}` | `Content-Type: application/x-www-form-urlencoded` only | Form body: `client_id=X&client_secret=Y&scope=Z&grant_type=client_credentials` | `TokenRespModel`: `{access_token,token_type,expires_in,refresh_token,scope}` | Fully implemented but **not called from any live path** — only from commented-out wrapper code. |

---

## 12. Summary counts

| Domain | Operations documented |
|---|---|
| **Sale Engine** | 53 |
| **Register** | 6 unique endpoints (7 call sites) |
| **Flight** | 3 |
| **Print Hub** | 1 |
| **Cash Card** | 1 |
| **Member** | 2 (both dead code; 1 additional bridge operation cross-listed under Sale Engine) |
| *(Order Gateway, auxiliary — not counted in the 6)* | 4 |

## 13. Operations where response shape is genuinely UNKNOWN

In each case it is specifically the **request body** the client leaves untyped (`data: any`); the response
side is still constrained by the provider's generic type parameter in every case found:

- **`saleEngine.getShoppingInfo`** — request untyped; response: `ReturnObject<ShoppingInfo>`.
- **`saleEngine.getBankOfEDCList`** — request untyped; response: `ReturnObject<BankModel[]>`.
- **`saleEngine.SaveSignature`** — request untyped; response: `ReturnObject<OrderSignatureModel[]>`; illustrative request body above is a best-effort guess, not confirmed.
- **`saleEngine.GetCaratInformation`** — request untyped; response: `ReturnObject<CaratReponse>`.

No operation was found where the *response* itself is consumed as bare `any` with zero destructuring, within
the providers + models read for this task (43 active pages' call sites were not read in full — see
`inventory.md` for the page-level breakdown).
