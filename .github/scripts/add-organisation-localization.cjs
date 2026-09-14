const fs = require('fs');
const path = require('path');

const root = process.env.GITHUB_WORKSPACE || process.cwd();
const values = {
  en: {
    adminCreateOrganisation: 'Create organisation',
    adminRetryLoadingOrganisations: 'Retry loading organisations',
    adminNoOrganisations: 'No organisations created yet.',
    adminOrganisationCauseCount: '{count} causes',
    adminOrganisationActions: 'Organisation actions',
    adminDeleteOrganisation: 'Delete organisation',
    adminDeleteOrganisationTitle: 'Delete organisation?',
    adminDeleteOrganisationConfirmation: 'Delete “{organisation}” permanently? This cannot be undone. If it has donation allocations or beneficiary records, deletion will be blocked and the organisation must be deactivated instead.',
    adminDeleteOrganisationSuccess: '“{organisation}” was deleted.'
  },
  hi: {
    adminCreateOrganisation: 'संस्था बनाएँ',
    adminRetryLoadingOrganisations: 'संस्थाओं को लोड करने के लिए पुनः प्रयास करें',
    adminNoOrganisations: 'अभी तक कोई संस्था नहीं बनाई गई है।',
    adminOrganisationCauseCount: '{count} सेवा क्षेत्र',
    adminOrganisationActions: 'संस्था के विकल्प',
    adminDeleteOrganisation: 'संस्था हटाएँ',
    adminDeleteOrganisationTitle: 'संस्था हटाएँ?',
    adminDeleteOrganisationConfirmation: 'क्या आप “{organisation}” को स्थायी रूप से हटाना चाहते हैं? इसे वापस नहीं किया जा सकता। यदि इसमें दान आवंटन या लाभार्थी रिकॉर्ड हैं, तो हटाना रोका जाएगा और संस्था को निष्क्रिय करना होगा।',
    adminDeleteOrganisationSuccess: '“{organisation}” हटा दी गई।'
  },
  mr: {
    adminCreateOrganisation: 'संस्था तयार करा',
    adminRetryLoadingOrganisations: 'संस्था लोड करण्यासाठी पुन्हा प्रयत्न करा',
    adminNoOrganisations: 'अद्याप कोणतीही संस्था तयार केलेली नाही.',
    adminOrganisationCauseCount: '{count} सेवा क्षेत्रे',
    adminOrganisationActions: 'संस्था कृती',
    adminDeleteOrganisation: 'संस्था हटवा',
    adminDeleteOrganisationTitle: 'संस्था हटवायची?',
    adminDeleteOrganisationConfirmation: '“{organisation}” कायमची हटवायची का? ही कृती पूर्ववत करता येणार नाही. दान वाटप किंवा लाभार्थी नोंदी असल्यास हटवणे रोखले जाईल आणि संस्था निष्क्रिय करावी लागेल.',
    adminDeleteOrganisationSuccess: '“{organisation}” हटवली.'
  },
  gu: {
    adminCreateOrganisation: 'સંસ્થા બનાવો',
    adminRetryLoadingOrganisations: 'સંસ્થાઓ લોડ કરવા માટે ફરી પ્રયાસ કરો',
    adminNoOrganisations: 'હજુ સુધી કોઈ સંસ્થા બનાવવામાં આવી નથી.',
    adminOrganisationCauseCount: '{count} કારણો',
    adminOrganisationActions: 'સંસ્થાની ક્રિયાઓ',
    adminDeleteOrganisation: 'સંસ્થા કાઢી નાખો',
    adminDeleteOrganisationTitle: 'સંસ્થા કાઢી નાખવી છે?',
    adminDeleteOrganisationConfirmation: 'શું તમે “{organisation}”ને કાયમ માટે કાઢી નાખવા માંગો છો? આ પાછું કરી શકાશે નહીં. જો તેમાં દાન ફાળવણી અથવા લાભાર્થી રેકોર્ડ હોય, તો કાઢી નાખવાનું અટકાવવામાં આવશે અને સંસ્થાને નિષ્ક્રિય કરવી પડશે.',
    adminDeleteOrganisationSuccess: '“{organisation}” કાઢી નાખવામાં આવી.'
  }
};

for (const [locale, entries] of Object.entries(values)) {
  const file = path.join(root, 'app/flutter/lib/l10n', `app_${locale}.arb`);
  let text = fs.readFileSync(file, 'utf8');
  if (text.includes('"adminDeleteOrganisation"')) continue;
  const lines = [];
  for (const [key, value] of Object.entries(entries)) {
    lines.push(`  ${JSON.stringify(key)}: ${JSON.stringify(value)}`);
    if (key === 'adminOrganisationCauseCount') lines.push('  "@adminOrganisationCauseCount": {"placeholders": {"count": {}}}');
    if (key === 'adminDeleteOrganisationConfirmation') lines.push('  "@adminDeleteOrganisationConfirmation": {"placeholders": {"organisation": {}}}');
    if (key === 'adminDeleteOrganisationSuccess') lines.push('  "@adminDeleteOrganisationSuccess": {"placeholders": {"organisation": {}}}');
  }
  const end = text.lastIndexOf('\n}');
  if (end < 0) throw new Error(`Invalid ARB: ${file}`);
  const body = text.slice(0, end).replace(/,?\s*$/, ',\n');
  fs.writeFileSync(file, body + lines.join(',\n') + text.slice(end));
}
