from odoo import models, api
import pytz
import re
from datetime import timedelta
from collections import OrderedDict
import unicodedata

def normalize_text(text):
        if text:
            return unicodedata.normalize('NFC', str(text))
        return ''
class AIViharReportMixin:
    """Mixin to share logic across all Vihar reports."""
    

    def _get_ist_datetime(self, utc_dt):
        """Convert UTC datetime to IST datetime"""
        if not utc_dt:
            return None
        ist_tz = pytz.timezone('Asia/Kolkata')
        utc_tz = pytz.utc
        return utc_tz.localize(utc_dt).astimezone(ist_tz)

    def _get_sorted_salutations(self, record):
        """Merge salutation_ids and auto_salutation_ids and sort them by rank hierarchy."""
        # Merge manual and auto salutations using recordset union (|)
        all_salutations = record.salutation_ids | record.auto_salutation_ids
        
        # Filter for active only (extra safety)
        active_salutations = all_salutations.filtered(lambda s: s.status == 'active')

        # Hierarchy mapping: DGP > CP > SP
        rank_priority = {
            'd.g.p.': 1,
            'c.p.': 2,
            's.p.': 3
        }

        # Sort by rank priority, then by name
        return active_salutations.sorted(key=lambda s: (rank_priority.get(s.salutation_prefix or '', 99), s.name_en or ''))

    

    def _get_cleaned_salutation_name(self, salutation, lang='en'):

        raw_name = getattr(salutation, f'name_{lang}', '') or ''
        prefix_key = (salutation.salutation_prefix or '').lower()

        # Translation mapping
        SALUTATION_TRANSLATIONS = {
            'dgp': {
                'gu': 'ડીજીપી',
                'hi': 'डीजीपी',
                'en': 'DGP',
            },
            'cp': {
                'gu': 'સીપી',
                'hi': 'सीपी',
                'en': 'CP',
            },
            'sp': {
                'gu': 'એસપી',
                'hi': 'एसपी',
                'en': 'SP',
            },
        }

        # Get location
        location = ""

        if salutation.district_id:
            location = getattr(salutation.district_id, f'name_{lang}', '') or ''

        elif salutation.state_id:
            location = getattr(salutation.state_id, f'name_{lang}', '') or ''

        location = re.sub(r'\s+', ' ', location).strip()

        # =========================
        # Gujarati
        # =========================
        if lang == 'gu':

            prefix_trans = SALUTATION_TRANSLATIONS.get(prefix_key, {}).get('gu', '')

            if prefix_trans:
                base = f"માનનીય શ્રી {prefix_trans} સાહેબ શ્રી"

                return f"{base} {location}".strip() if location else base

            else:
                name = re.sub(r'શ્રી|સાહેબ|સિટી', '', raw_name).strip()

                return f"માનનીય શ્રી {name} સાહેબ શ્રી".strip()

        # =========================
        # Hindi
        # =========================
        elif lang == 'hi':

            prefix_trans = SALUTATION_TRANSLATIONS.get(prefix_key, {}).get('hi', '')

            if prefix_trans:
                base = f"माननीय श्री {prefix_trans} साहब श्री"

                return f"{base} {location}".strip() if location else base

            else:
                name = re.sub(r'श्री|साहब|सिटी', '', raw_name).strip()

                return f"माननीय श्री {name} साहब श्री".strip()

        # =========================
        # English
        # =========================
        else:

            prefix_trans = SALUTATION_TRANSLATIONS.get(prefix_key, {}).get('en', '')

            if prefix_trans:
                base = f"Respected Sir {prefix_trans}"

                return f"{base} {location}".strip() if location else base

            else:
                name = re.sub(r'sir\s*shree', '', raw_name, flags=re.IGNORECASE)
                name = re.sub(r'\bcity\b', '', name, flags=re.IGNORECASE)
                name = re.sub(r'\s+', ' ', name)

                return f"Respected Sir {name.strip()}".strip()
            
    def _get_formatted_mahatma_name(self, record, lang='gu'):
    
        name = getattr(record.code, f'name_{lang}', '') or ''

        # Normalize Unicode text
        name = normalize_text(name)

        prefixes = {
            'gu': ['જૈન સાધ્વી શ્રી', 'પૂ. સાધ્વી શ્રી', 'પૂજ્ય સાધ્વી શ્રી'],
            'en': ['Jain Sadhvi Shree', 'Pujya Sadhvi Shree'],
            'hi': ['जैन साध्वी श्री', 'पूज्य साध्वी श्री']
        }

        suffixes = {
            'gu': ['મ.સા.', 'મા. સા.'],
            'en': ['M.S.', 'M. Sa.'],
            'hi': ['म.सा.', 'मा. सा.']
        }

        # Check for existing prefix
        has_prefix = any(name.strip().startswith(p) for p in prefixes.get(lang, []))

        # Check for existing suffix
        has_suffix = any(name.strip().endswith(s) for s in suffixes.get(lang, []))

        result = name

        if not has_prefix:
            prefix_map = {
                'gu': 'જૈન સાધ્વી શ્રી',
                'en': 'Jain Sadhvi Shree',
                'hi': 'जैन साध्वी श्री'
            }

            result = f"{prefix_map.get(lang, '')} {result}".strip()

        if not has_suffix:
            suffix_map = {
                'gu': 'મ.સા.',
                'en': 'M.S.',
                'hi': 'म.सा.'
            }

            result = f"{result} {suffix_map.get(lang, '')}".strip()

        # Final normalization
        return normalize_text(result)

    def _get_district_display(self, route, lang='gu'):
        """Return both districts if different, otherwise one."""

        from_dist = route.from_location_id.district_id
        to_dist = route.to_location_id.district_id

        name_field = f'name_{lang}'

        from_name = getattr(from_dist, name_field, '') or ''
        to_name = getattr(to_dist, name_field, '') or ''

        # Normalize Unicode text
        from_name = normalize_text(from_name)
        to_name = normalize_text(to_name)

        if from_name and to_name and from_name != to_name:
            return normalize_text(f"{from_name} / {to_name}")

        return normalize_text(to_name or from_name or '-')

    def _get_sorted_routes(self, record):
        """Return Vihar routes sorted DESC by date-time for PDF display."""
        if not record or not record.vihar_id:
            return []
        return record.vihar_id.sorted(key=lambda r: r.vihar_date_time or '', reverse=False)

# --- Detail Reports (ai.add.vihar) ---

class ReportAddViharEn(models.AbstractModel, AIViharReportMixin):
    _name = "report.ai_vihar.report_add_vihar_english"
    _description = "English Vihar Info Report"

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env['ai.add.vihar'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'ai.add.vihar',
            'docs': docs,
            'get_ist_datetime': self._get_ist_datetime,
            'get_sorted_salutations': self._get_sorted_salutations,
            'get_cleaned_salutation_name': self._get_cleaned_salutation_name,
            'get_formatted_mahatma_name': self._get_formatted_mahatma_name,
            'get_district_display': self._get_district_display,
            'get_sorted_routes': self._get_sorted_routes,
        }

class ReportAddViharGu(models.AbstractModel, AIViharReportMixin):
    _name = "report.ai_vihar.report_add_vihar_gujarati"
    _description = "Gujarati Vihar Info Report"

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env['ai.add.vihar'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'ai.add.vihar',
            'docs': docs,
            'get_ist_datetime': self._get_ist_datetime,
            'get_sorted_salutations': self._get_sorted_salutations,
            'get_cleaned_salutation_name': self._get_cleaned_salutation_name,
            'get_formatted_mahatma_name': self._get_formatted_mahatma_name,
            'get_district_display': self._get_district_display,
            'get_sorted_routes': self._get_sorted_routes,
        }

class ReportAddViharHi(models.AbstractModel, AIViharReportMixin):
    _name = "report.ai_vihar.report_add_vihar_hindi"
    _description = "Hindi Vihar Info Report"

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env['ai.add.vihar'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'ai.add.vihar',
            'docs': docs,
            'get_ist_datetime': self._get_ist_datetime,
            'get_sorted_salutations': self._get_sorted_salutations,
            'get_cleaned_salutation_name': self._get_cleaned_salutation_name,
            'get_formatted_mahatma_name': self._get_formatted_mahatma_name,
            'get_district_display': self._get_district_display,
            'get_sorted_routes': self._get_sorted_routes,
        }

# --- Summary Reports (ai.vihar.route) ---

class ReportViharRouteEn(models.AbstractModel, AIViharReportMixin):
    _name = "report.ai_vihar.pdf_template_report_english"
    _description = "English Vihar Summary Report"

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env['ai.vihar.route'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'ai.vihar.route',
            'docs': docs,
            'get_ist_datetime': self._get_ist_datetime,
            'get_district_display': self._get_district_display,
            'get_sorted_routes': self._get_sorted_routes,
        }

class ReportViharRouteGu(models.AbstractModel, AIViharReportMixin):
    _name = "report.ai_vihar.pdf_template_report_gujarati"
    _description = "Gujarati Vihar Summary Report"

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env['ai.vihar.route'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'ai.vihar.route',
            'docs': docs,
            'get_ist_datetime': self._get_ist_datetime,
            'get_district_display': self._get_district_display,
            'get_sorted_routes': self._get_sorted_routes,
        }

class ReportViharRouteHi(models.AbstractModel, AIViharReportMixin):
    _name = "report.ai_vihar.pdf_template_report_hindi"
    _description = "Hindi Vihar Summary Report"

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env['ai.vihar.route'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'ai.vihar.route',
            'docs': docs,
            'get_ist_datetime': self._get_ist_datetime,
            'get_district_display': self._get_district_display,
            'get_sorted_routes': self._get_sorted_routes,
        }