#include "include/fortune_sheet/fortune_sheet_plugin.h"

#include <windows.h>
#include <dwrite.h>

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <set>
#include <string>

namespace {

constexpr char kFontChannelName[] = "fortune_sheet/fonts";
constexpr char kListFontFamiliesMethod[] = "listFontFamilies";

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string, -1, nullptr, 0, nullptr,
      nullptr) -
      1;
  int input_length = static_cast<int>(wcslen(utf16_string));
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string, input_length,
      utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

std::wstring NormalizeFontFamilyName(const std::wstring& value) {
  std::wstring family = value;
  for (auto& character : family) {
    if (character == L'_' || character == L'-' || character == L'\t' ||
        character == L'\r' || character == L'\n') {
      character = L' ';
    }
  }
  const auto first = family.find_first_not_of(L" ");
  if (first == std::wstring::npos) {
    return L"";
  }
  const auto last = family.find_last_not_of(L" ");
  std::wstring trimmed = family.substr(first, last - first + 1);
  std::wstring collapsed;
  collapsed.reserve(trimmed.size());
  bool previous_space = false;
  for (const auto character : trimmed) {
    if (character == L' ') {
      if (!previous_space) {
        collapsed.push_back(character);
      }
      previous_space = true;
    } else {
      collapsed.push_back(character);
      previous_space = false;
    }
  }
  return collapsed;
}

int CALLBACK EnumFontFamilyCallback(const LOGFONTW* font,
                                    const TEXTMETRICW*, DWORD, LPARAM data) {
  auto* families = reinterpret_cast<std::set<std::wstring>*>(data);
  if (font->lfFaceName[0] != L'@') {
    const auto family = NormalizeFontFamilyName(font->lfFaceName);
    if (!family.empty()) {
      families->insert(family);
    }
  }
  return 1;
}

bool AddLocalizedFamilyName(IDWriteLocalizedStrings* names,
                            std::set<std::wstring>* families) {
  if (names == nullptr || families == nullptr) {
    return false;
  }
  UINT32 index = 0;
  BOOL exists = FALSE;
  wchar_t locale_name[LOCALE_NAME_MAX_LENGTH] = {};
  if (GetUserDefaultLocaleName(locale_name, LOCALE_NAME_MAX_LENGTH) != 0) {
    names->FindLocaleName(locale_name, &index, &exists);
  }
  if (!exists) {
    names->FindLocaleName(L"en-us", &index, &exists);
  }
  if (!exists) {
    index = 0;
  }
  UINT32 length = 0;
  if (FAILED(names->GetStringLength(index, &length)) || length == 0) {
    return false;
  }
  std::wstring family(length + 1, L'\0');
  if (FAILED(names->GetString(index, family.data(), length + 1))) {
    return false;
  }
  family.resize(length);
  family = NormalizeFontFamilyName(family);
  if (family.empty() || family[0] == L'@') {
    return false;
  }
  families->insert(family);
  return true;
}

bool AddDirectWriteFontFamilies(std::set<std::wstring>* families) {
  IDWriteFactory* factory = nullptr;
  HRESULT result = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED,
                                       __uuidof(IDWriteFactory),
                                       reinterpret_cast<IUnknown**>(&factory));
  if (FAILED(result) || factory == nullptr) {
    return false;
  }
  IDWriteFontCollection* collection = nullptr;
  result = factory->GetSystemFontCollection(&collection, FALSE);
  if (FAILED(result) || collection == nullptr) {
    factory->Release();
    return false;
  }
  const UINT32 count = collection->GetFontFamilyCount();
  for (UINT32 index = 0; index < count; ++index) {
    IDWriteFontFamily* family = nullptr;
    if (FAILED(collection->GetFontFamily(index, &family)) ||
        family == nullptr) {
      continue;
    }
    IDWriteLocalizedStrings* names = nullptr;
    if (SUCCEEDED(family->GetFamilyNames(&names)) && names != nullptr) {
      AddLocalizedFamilyName(names, families);
      names->Release();
    }
    family->Release();
  }
  collection->Release();
  factory->Release();
  return !families->empty();
}

void AddGdiFontFamilies(std::set<std::wstring>* families) {
  if (families == nullptr) {
    return;
  }
  HDC hdc = GetDC(nullptr);
  if (hdc != nullptr) {
    LOGFONTW log_font = {};
    log_font.lfCharSet = DEFAULT_CHARSET;
    EnumFontFamiliesExW(
        hdc, &log_font,
        reinterpret_cast<FONTENUMPROCW>(EnumFontFamilyCallback),
        reinterpret_cast<LPARAM>(families), 0);
    ReleaseDC(nullptr, hdc);
  }
}

flutter::EncodableList InstalledFontFamilies() {
  std::set<std::wstring> families;
  if (!AddDirectWriteFontFamilies(&families)) {
    AddGdiFontFamilies(&families);
  }

  flutter::EncodableList result;
  result.reserve(families.size());
  for (const auto& family : families) {
    result.emplace_back(Utf8FromUtf16(family.c_str()));
  }
  return result;
}

class FortuneSheetPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FortuneSheetPlugin() = default;
  virtual ~FortuneSheetPlugin() = default;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

void FortuneSheetPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kFontChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FortuneSheetPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

void FortuneSheetPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == kListFontFamiliesMethod) {
    result->Success(flutter::EncodableValue(InstalledFontFamilies()));
    return;
  }
  result->NotImplemented();
}

}  // namespace

void FortuneSheetPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FortuneSheetPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
