/// Automation IDs (handheld spec decision 6) — the single source for both
/// `TestId` wrappers in widgets and `byTestId` / `bySemanticsIdentifier`
/// finders in tests. Format: `<screen>.<element>` in lowerCamel. Android
/// exposes these as `resource-id`, iOS as `accessibilityIdentifier`.
///
/// Add new IDs here in the screen's group; never inline string literals.
abstract class NavIds {
  static const home = 'nav.home';
  static const sale = 'nav.sale';
  static const enquiry = 'nav.enquiry';
  static const menu = 'nav.menu';
  static const customer = 'nav.customer';
  static const setup = 'nav.setup';
  static const signOut = 'nav.signOut';
}

abstract class MenuIds {
  static const sheet = 'menu.sheet';
  static const settings = 'menu.settings';
  static const logout = 'menu.logout';
}

abstract class LoginIds {
  static const userCodeField = 'login.userCodeField';
  static const passwordField = 'login.passwordField';
  static const passwordVisibility = 'login.passwordVisibility';
  static const signInButton = 'login.signInButton';
  static const qrLoginButton = 'login.qrLoginButton';
  static const settingsButton = 'login.settingsButton';
  static const errorMessage = 'login.errorMessage';
}

abstract class HomeIds {
  static const greeting = 'home.greeting';
  static const sessionLine = 'home.sessionLine';
  static const onlineStatus = 'home.onlineStatus';
  static const billsStat = 'home.billsStat';
  static const netSalesStat = 'home.netSalesStat';
  static const scanField = 'home.scanField';
  static const tileRegister = 'home.tile.register';
  static const tileSale = 'home.tile.sale';
  static const tileCheckout = 'home.tile.checkout';
  static const tileEnquiry = 'home.tile.enquiry';
  static const suspendedBills = 'home.suspendedBills';
  static const customerResult = 'home.customerResult';

  /// One customer lookup result tile on the handheld Home.
  static String customerTile(int index) => 'home.customerTile.$index';
}

abstract class SettingsIds {
  static const saveButton = 'settings.saveButton';
  static const cancelButton = 'settings.cancelButton';
  static const terminalSection = 'settings.terminalSection';
  static const saleModeSection = 'settings.saleModeSection';
  static const sellOnline = 'settings.saleMode.online';
  static const sellOffline = 'settings.saleMode.offline';
  static const endpointsSection = 'settings.endpointsSection';
  static const deviceSection = 'settings.deviceSection';
}

abstract class SaleIds {
  static const header = 'sale.header';
  static const backButton = 'sale.backButton';
  static const scanField = 'sale.scanField';
  static const scanError = 'sale.scanError';
  static const staleNotice = 'sale.staleNotice';
  static const totalLine = 'sale.totalLine';
  static const netPay = 'sale.netPay';
  static const tabBuying = 'sale.tab.buying';
  static const tabBasket = 'sale.tab.basket';
  static const backToBuyingButton = 'sale.backToBuyingButton';
  static const emptyState = 'sale.emptyState';
  static const privilege = 'sale.privilege';
  static const basketNotice = 'sale.basketNotice';
  static const checkoutButton = 'sale.checkoutButton';
  static const customerButton = 'sale.customerButton';
  static const discountButton = 'sale.discountButton';
  static const saveButton = 'sale.saveButton';
  static const moreButton = 'sale.moreButton';
  static const moreSheet = 'sale.moreSheet';
  static const orderTypeShopping = 'sale.orderType.shopping';
  static const orderTypeDelivery = 'sale.orderType.delivery';
  static const orderTypePreOrder = 'sale.orderType.preOrder';
  static const voidConfirm = 'sale.voidConfirm';

  /// One cart line, keyed by its cart `row`.
  static String line(String row) => 'sale.line.$row';
}

abstract class EditLineIds {
  static const page = 'editLine.page';
  static const undoButton = 'editLine.undoButton';
  static const saveButton = 'editLine.saveButton';
  static const saveCloseButton = 'editLine.saveCloseButton';
  static const qtyDecrease = 'editLine.qty.decrease';
  static const qtyIncrease = 'editLine.qty.increase';
  static const qtyValue = 'editLine.qty.value';
  static const amount = 'editLine.amount';
  static const netAmount = 'editLine.netAmount';
  static const serialField = 'editLine.serialField';
  static const freezeSwitch = 'editLine.freezeSwitch';
  static const lockDiscountSwitch = 'editLine.lockDiscountSwitch';
  static const pickupCollect = 'editLine.pickup.collect';
  static const pickupTake = 'editLine.pickup.take';
  static const voidButton = 'editLine.voidButton';
}

abstract class DiscountIds {
  static const sheet = 'discount.sheet';
  static const closeButton = 'discount.closeButton';
  static const modePercent = 'discount.mode.percent';
  static const modeAmount = 'discount.mode.amount';
  static const modePromo = 'discount.mode.promo';
  static const modeNewPrice = 'discount.mode.newPrice';
  static const clearButton = 'discount.clearButton';
  static const lineDiscount = 'discount.lineDiscount';
  static const billDelta = 'discount.billDelta';
  static const promotions = 'discount.promotions';
  static const valueField = 'discount.valueField';
  static const netPreview = 'discount.netPreview';
  static const applyButton = 'discount.applyButton';
  static const cancelButton = 'discount.cancelButton';

  static String preset(int percent) => 'discount.preset.$percent';
}

abstract class CheckoutIds {
  static const page = 'checkout.page';
  static const netPay = 'checkout.netPay';
  static const summaryLine = 'checkout.summaryLine';
  static const flagsNotice = 'checkout.flagsNotice';
  static const customerCard = 'checkout.customerCard';
  static const amountsCard = 'checkout.amountsCard';
  static const totalAmount = 'checkout.amount.total';
  static const grandAmount = 'checkout.amount.grand';
  static const signatureRow = 'checkout.signatureRow';
  static const takePaymentButton = 'checkout.takePaymentButton';
  static const suspendButton = 'checkout.suspendButton';
  static const printQuoteButton = 'checkout.printQuoteButton';
}

abstract class PaymentIds {
  static const page = 'payment.page';
  static const netPay = 'payment.netPay';
  static const tendered = 'payment.tendered';
  static const remaining = 'payment.remaining';
  static const amountField = 'payment.amountField';
  static const presetAllRemaining = 'payment.preset.allRemaining';
  static const presetHalf = 'payment.preset.half';
  static const preset10000 = 'payment.preset.10000';
  static const preset20000 = 'payment.preset.20000';
  static const ledger = 'payment.ledger';
  static const ledgerEmpty = 'payment.ledgerEmpty';
  static const chargeButton = 'payment.chargeButton';
  static const completeSaleButton = 'payment.completeSaleButton';
  static const chargeNotice = 'payment.chargeNotice';
  static const cashReceivedField = 'payment.cashReceivedField';
  static const cashApplied = 'payment.cashApplied';
  static const cashChangeDue = 'payment.cashChangeDue';
  static const recordedChange = 'payment.recordedChange';
  static const takeCashButton = 'payment.takeCashButton';
  static const paymentError = 'payment.paymentError';

  static String method(String name) => 'payment.method.$name';
  static String ledgerRow(int index) => 'payment.ledger.$index';
}

abstract class WalletIds {
  static const scanPage = 'wallet.scanPage';
  static const chargeAmount = 'wallet.chargeAmount';
  static const codeField = 'wallet.codeField';
  static const detectedCode = 'wallet.detectedCode';
  static const unknownCode = 'wallet.unknownCode';
  static const sendChargeButton = 'wallet.sendChargeButton';
  static const cancelButton = 'wallet.cancelButton';
  static const rescanButton = 'wallet.rescanButton';
  static const showQrButton = 'wallet.showQrButton';

  static String step(String name) => 'wallet.step.$name';

  static const queryPage = 'wallet.queryPage';
  static const queryButton = 'wallet.queryButton';
  static const queryResult = 'wallet.queryResult';
  static const voidButton = 'wallet.voidButton';
  static const printButton = 'wallet.printButton';

  static const voidPage = 'wallet.voidPage';
  static const voidAmount = 'wallet.voidAmount';
  static const voidReason = 'wallet.voidReason';
  static const managerApproval = 'wallet.managerApproval';
  static const confirmVoidButton = 'wallet.confirmVoidButton';
}

abstract class SignatureIds {
  static const page = 'signature.page';
  static const closeButton = 'signature.closeButton';
  static const saveButton = 'signature.saveButton';
  static const bottomSaveButton = 'signature.bottomSaveButton';
  static const cancelButton = 'signature.cancelButton';
  static const paidByPad = 'signature.paidBy.pad';
  static const paidByClear = 'signature.paidBy.clear';
  static const paidByStatus = 'signature.paidBy.status';
  static const customerPad = 'signature.customer.pad';
  static const customerClear = 'signature.customer.clear';
  static const customerStatus = 'signature.customer.status';
}

abstract class FlightPickerIds {
  static const sheet = 'flightPicker.sheet';
  static const closeButton = 'flightPicker.closeButton';
  static const selectedDate = 'flightPicker.selectedDate';
  static const selectedTime = 'flightPicker.selectedTime';
  static const monthLabel = 'flightPicker.monthLabel';
  static const previousMonth = 'flightPicker.previousMonth';
  static const nextMonth = 'flightPicker.nextMonth';
  static const confirmButton = 'flightPicker.confirmButton';
  static const cancelButton = 'flightPicker.cancelButton';

  /// A day cell, `yyyy-mm-dd`.
  static String day(DateTime date) =>
      'flightPicker.day.${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}

abstract class RegisterIds {
  static const page = 'register.page';
  static const scanPassportButton = 'register.scanPassportButton';
  static const travellerSection = 'register.travellerSection';
  static const contactSection = 'register.contactSection';
  static const agentSection = 'register.agentSection';
  static const submitButton = 'register.submitButton';
  static const cancelButton = 'register.cancelButton';
}

abstract class ProfileIds {
  static const page = 'profile.page';
  static const name = 'profile.name';
  static const badge = 'profile.badge';
  static const cardLine = 'profile.cardLine';
  static const status = 'profile.status';
  static const pointsStat = 'profile.stat.points';
  static const ePurseStat = 'profile.stat.ePurse';
  static const spendStat = 'profile.stat.spend';
  static const visitsStat = 'profile.stat.visits';
  static const flightCard = 'profile.flightCard';
  static const privileges = 'profile.privileges';
  static const recentPurchases = 'profile.recentPurchases';
  static const attachButton = 'profile.attachButton';
  static const editButton = 'profile.editButton';
  static const travellerButton = 'profile.travellerButton';

  static String privilege(int index) => 'profile.privilege.$index';
}

abstract class TravellerIds {
  static const page = 'traveller.page';
  static const passportCard = 'traveller.passportCard';
  static const mrzScanButton = 'traveller.mrzScanButton';
  static const flightSearch = 'traveller.flightSearch';
  static const flightEmpty = 'traveller.flightEmpty';
  static const saveButton = 'traveller.saveButton';
  static const cancelButton = 'traveller.cancelButton';

  static String flight(int index) => 'traveller.flight.$index';
}

abstract class EnquiryIds {
  static const searchField = 'enquiry.searchField';
  static const filterToday = 'enquiry.filter.today';
  static const filterMine = 'enquiry.filter.mine';
  static const filterNotPicked = 'enquiry.filter.notPicked';
  static const filterRefunded = 'enquiry.filter.refunded';
  static const resultsNotice = 'enquiry.resultsNotice';
  static const reprintButton = 'enquiry.reprintButton';
  static const refundButton = 'enquiry.refundButton';
}

/// Desktop-only elements (≥ 840 dp). Elements shared with the handheld
/// layout reuse that screen's ids (LoginIds, SettingsIds, EnquiryIds, …)
/// so one automation script can drive both.
abstract class DesktopIds {
  static const topBar = 'desktop.topBar';
  static const userChip = 'desktop.userChip';

  // Sign in (S1)
  static const loginIdentityPanel = 'desktop.login.identityPanel';
  static const loginRememberUser = 'desktop.login.rememberUser';
  static const loginIdCardButton = 'desktop.login.idCardButton';

  // Home dashboard (S2)
  static const homeGreeting = 'desktop.home.greeting';
  static const homeShiftLine = 'desktop.home.shiftLine';
  static const homeBillsKpi = 'desktop.home.kpi.bills';
  static const homeNetSalesKpi = 'desktop.home.kpi.netSales';
  static const homeAvgBillKpi = 'desktop.home.kpi.avgBill';
  static const homeScanField = 'desktop.home.scanField';
  static const homeNewSaleButton = 'desktop.home.newSaleButton';
  static const homeTileSale = 'desktop.home.tile.sale';
  static const homeTileRegistration = 'desktop.home.tile.registration';
  static const homeTileEnquiry = 'desktop.home.tile.enquiry';
  static const homeSuspendedBills = 'desktop.home.suspendedBills';
  static const homePromotions = 'desktop.home.promotions';

  // Enquiry (S10)
  static const enquiryDateRange = 'desktop.enquiry.dateRange';
  static const enquiryStatus = 'desktop.enquiry.status';
  static const enquirySearchButton = 'desktop.enquiry.searchButton';
  static const enquiryTable = 'desktop.enquiry.table';
  static const enquiryDetail = 'desktop.enquiry.detail';
  static const enquiryOpenBillButton = 'desktop.enquiry.openBillButton';

  // Settings (S11)
  static const settingsTerminalPanel = 'desktop.settings.terminalPanel';
  static const settingsPeripheralsPanel = 'desktop.settings.peripheralsPanel';
  static const settingsEndpointsPanel = 'desktop.settings.endpointsPanel';
  static const settingsDevicePanel = 'desktop.settings.devicePanel';
}

/// Desktop Sale (S3 / S4) elements not shared with the handheld Sale.
abstract class DesktopSaleIds {
  static const lookupButton = 'desktop.sale.lookupButton';
  static const qtyButton = 'desktop.sale.qtyButton';
  static const table = 'desktop.sale.table';
  static const summary = 'desktop.sale.summary';
  static const qtyTotal = 'desktop.sale.qtyTotal';
  static const lineCount = 'desktop.sale.lineCount';
  static const grand = 'desktop.sale.grand';
  static const removeButton = 'desktop.sale.removeButton';
  static const freezeButton = 'desktop.sale.freezeButton';
  static const pickupButton = 'desktop.sale.pickupButton';
  static const selectionHint = 'desktop.sale.selectionHint';
  static const suspendButton = 'desktop.sale.suspendButton';
  static const printBasketButton = 'desktop.sale.printBasketButton';
  static const claimCheckButton = 'desktop.sale.claimCheckButton';

  static String qtyDecrease(String row) => 'desktop.sale.line.$row.qtyDecrease';
  static String qtyIncrease(String row) => 'desktop.sale.line.$row.qtyIncrease';
}

/// Desktop Customer (S8), Flight & passport (S9) and flight date picker
/// (S12) elements not shared with handheld. Shared ones reuse
/// [RegisterIds], [ProfileIds], [TravellerIds] and [FlightPickerIds].
abstract class DesktopCustomerIds {
  // S12 flight date & time
  static const flightPicker = 'desktop.flightPicker';
  static String departure(int index) => 'desktop.flightPicker.departure.$index';

  // S8 form
  static const form = 'desktop.customer.form';
  static const flightCode = 'desktop.customer.flightCode';
  static const flightDate = 'desktop.customer.flightDate';
  static const passportNo = 'desktop.customer.passportNo';
  static const englishName = 'desktop.customer.englishName';
  static const gender = 'desktop.customer.gender';
  static const nationality = 'desktop.customer.nationality';
  static const email = 'desktop.customer.email';
  static const mobile = 'desktop.customer.mobile';
  static const weChat = 'desktop.customer.weChat';
  static const customerType = 'desktop.customer.customerType';
  static const agentCode = 'desktop.customer.agentCode';
  static const subAgentCode = 'desktop.customer.subAgentCode';
  static const nonInternational = 'desktop.customer.nonInternational';
  static const undoButton = 'desktop.customer.undoButton';
  static const travellerButton = 'desktop.customer.travellerButton';

  // S8 tab
  static const searchField = 'desktop.customer.searchField';
  static const searchButton = 'desktop.customer.searchButton';
  static const newCustomerButton = 'desktop.customer.newCustomerButton';
  static const registerMemberButton = 'desktop.customer.registerMemberButton';
  static const matchedCard = 'desktop.customer.matchedCard';
  static const profile = 'desktop.customer.profile';
  static const profileEmpty = 'desktop.customer.profileEmpty';
  static String result(int index) => 'desktop.customer.result.$index';

  // S9 flight & passport
  static const traveller = 'desktop.traveller';
  static const travellerPassportNo = 'desktop.traveller.passportNo';
  static const travellerName = 'desktop.traveller.englishName';
  static const travellerNationality = 'desktop.traveller.nationality';
  static const boardingPassButton = 'desktop.traveller.boardingPassButton';
  static const collectionPoint = 'desktop.traveller.collectionPoint';
  static String travellerFilter(String key) => 'desktop.traveller.filter.$key';
}

/// Desktop lookup field (S13) parts, derived from the field's own id.
abstract class DesktopLookupIds {
  static String open(String fieldId) => '$fieldId.open';
  static String list(String fieldId) => '$fieldId.list';
  static String option(String fieldId, int index) => '$fieldId.option.$index';
}

/// Order currency (legacy Sale / Checkout currency button and
/// `CurrencyPickerPage`) and the CHANGE screen (legacy `ChangePage`) —
/// shared by the desktop and handheld layouts.
abstract class CurrencyIds {
  static const orderButton = 'currency.orderButton';
  static const rate = 'currency.rate';
  static const netPayBase = 'currency.netPayBase';
  static const error = 'currency.error';
  static const picker = 'currency.picker';
  static const search = 'currency.search';

  static String option(String code) => 'currency.option.$code';

  // CHANGE screen
  static const changeButton = 'currency.change.openButton';
  static const changeScreen = 'currency.change.screen';
  static const changeRate = 'currency.change.rate';
  static const changeAmountThb = 'currency.change.amountThb';
  static const changeCurrencyField = 'currency.change.currencyField';
  static const changeCurrencyThb = 'currency.change.currencyThb';
  static const changeLocal = 'currency.change.local';
  static const changeError = 'currency.change.error';
  static const changeSaveButton = 'currency.change.saveButton';
  static const changeCancelButton = 'currency.change.cancelButton';

  static String changeCurrency(String code) => 'currency.change.option.$code';
}

/// Desktop Checkout (S5) / Payment (S6) elements not shared with handheld.
abstract class DesktopPaymentIds {
  static const wizardSteps = 'desktop.wizard.steps';
  static const wizardEscape = 'desktop.wizard.escape';
  static const linesTable = 'desktop.checkout.linesTable';
  static const flightCard = 'desktop.checkout.flightCard';
  static const signatureBox = 'desktop.checkout.signatureBox';
  static const detailPanel = 'desktop.payment.detailPanel';
  static const tenderedField = 'desktop.payment.tenderedField';
  static const appliedToBill = 'desktop.payment.appliedToBill';
  static const changeDue = 'desktop.payment.changeDue';
  static const addTenderButton = 'desktop.payment.addTenderButton';
  static const openDrawerButton = 'desktop.payment.openDrawerButton';
  static const exactChip = 'desktop.payment.quick.exact';
  static const keypadBackspace = 'desktop.payment.keypad.backspace';

  static String currency(String code) => 'desktop.payment.currency.$code';
  static String quick(int amount) => 'desktop.payment.quick.$amount';
  static String keypad(String key) => 'desktop.payment.keypad.$key';
}
