package org.grobid.core.document;

import com.google.common.base.Joiner;
import com.google.common.collect.Sets;
import nu.xom.Attribute;
import nu.xom.Element;
import nu.xom.Node;
import nu.xom.Text;
import org.grobid.core.GrobidModels;
import org.grobid.core.data.*;
import org.grobid.core.data.Date;
import org.grobid.core.document.xml.XmlBuilderUtils;
import org.grobid.core.engines.Engine;
import org.grobid.core.engines.label.SegmentationLabels;
import org.grobid.core.engines.config.GrobidAnalysisConfig;
import org.grobid.core.engines.counters.ReferenceMarkerMatcherCounters;
import org.grobid.core.engines.label.TaggingLabel;
import org.grobid.core.engines.label.TaggingLabels;
import org.grobid.core.exceptions.GrobidException;
import org.grobid.core.lang.Language;
import org.grobid.core.layout.BoundingBox;
import org.grobid.core.layout.GraphicObject;
import org.grobid.core.layout.LayoutToken;
import org.grobid.core.layout.LayoutTokenization;
import org.grobid.core.tokenization.TaggingTokenCluster;
import org.grobid.core.tokenization.TaggingTokenClusteror;
import org.grobid.core.utilities.*;
import org.grobid.core.utilities.counters.CntManager;
import org.grobid.core.utilities.matching.EntityMatcherException;
import org.grobid.core.utilities.matching.ReferenceMarkerMatcher;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.grobid.core.document.xml.XmlBuilderUtils.teiElement;

/**
 * Class for generating a TEI representation of a document.
 *
 * @author Patrice Lopez
 */
@SuppressWarnings("StringConcatenationInsideStringBuilderAppend")
public class TEIFormatter {
    private Document doc = null;
    public static final Set<TaggingLabel> MARKER_LABELS = Sets.newHashSet(
            TaggingLabels.CITATION_MARKER,
            TaggingLabels.FIGURE_MARKER,
            TaggingLabels.TABLE_MARKER,
            TaggingLabels.EQUATION_MARKER);

    // possible association to Grobid customised TEI schemas: DTD, XML schema, RelaxNG or compact RelaxNG
    // DEFAULT means no schema association in the generated XML documents
    public enum SchemaDeclaration {
        DEFAULT, DTD, XSD, RNG, RNC
    }

    private Boolean inParagraph = false;

    private ArrayList<String> elements = null;

    // static variable for the position of italic and bold features in the CRF model
    private static final int ITALIC_POS = 16;
    private static final int BOLD_POS = 15;

    private static Pattern numberRef = Pattern.compile("(\\[|\\()\\d+\\w?(\\)|\\])");
    private static Pattern numberRefCompact =
            Pattern.compile("(\\[|\\()((\\d)+(\\w)?(\\-\\d+\\w?)?,\\s?)+(\\d+\\w?)(\\-\\d+\\w?)?(\\)|\\])");
    private static Pattern numberRefCompact2 = Pattern.compile("(\\[|\\()(\\d+)(-|‒|–|—|―|\u2013)(\\d+)(\\)|\\])");

    private static Pattern startNum = Pattern.compile("^(\\d+)(.*)");

    public TEIFormatter(Document document) {
        doc = document;
    }

    public StringBuilder toTEIHeader(BiblioItem biblio,
                                     String defaultPublicationStatement,
                                     GrobidAnalysisConfig config) {
        return toTEIHeader(biblio, SchemaDeclaration.XSD,
                defaultPublicationStatement, config);
    }

    public StringBuilder toTEIHeader(BiblioItem biblio,
                                     SchemaDeclaration schemaDeclaration,
                                     String defaultPublicationStatement,
                                     GrobidAnalysisConfig config) {
        StringBuilder tei = new StringBuilder();
        tei.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        if (config.isWithXslStylesheet()) {
            tei.append("<?xml-stylesheet type=\"text/xsl\" href=\"../jsp/xmlverbatimwrapper.xsl\"?> \n");
        }
        if (schemaDeclaration == SchemaDeclaration.DTD) {
            tei.append("<!DOCTYPE TEI SYSTEM \"" + GrobidProperties.get_GROBID_HOME_PATH()
                    + "/schemas/dtd/Grobid.dtd" + "\">\n");
        } else if (schemaDeclaration == SchemaDeclaration.XSD) {
            // XML schema
            tei.append("<TEI xmlns=\"http://www.tei-c.org/ns/1.0\" \n" +
                    "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \n" +
                    //"\n xsi:noNamespaceSchemaLocation=\"" +
                    //GrobidProperties.get_GROBID_HOME_PATH() + "/schemas/xsd/Grobid.xsd\""	+
                    "xsi:schemaLocation=\"http://www.tei-c.org/ns/1.0 " +
                    GrobidProperties.get_GROBID_HOME_PATH() + "/schemas/xsd/Grobid.xsd\"" +
                    "\n xmlns:xlink=\"http://www.w3.org/1999/xlink\">\n");
//				"\n xmlns:mml=\"http://www.w3.org/1998/Math/MathML\">\n");
        } else if (schemaDeclaration == SchemaDeclaration.RNG) {
            // standard RelaxNG
            tei.append("<?xml-model href=\"file://" +
                    GrobidProperties.get_GROBID_HOME_PATH() + "/schemas/rng/Grobid.rng" +
                    "\" schematypens=\"http://relaxng.org/ns/structure/1.0\"?>\n");
        } else if (schemaDeclaration == SchemaDeclaration.RNC) {
            // compact RelaxNG
            tei.append("<?xml-model href=\"file://" +
                    GrobidProperties.get_GROBID_HOME_PATH() + "/schemas/rng/Grobid.rnc" +
                    "\" type=\"application/relax-ng-compact-syntax\"?>\n");
        }
        // by default there is no schema association

        if (schemaDeclaration != SchemaDeclaration.XSD) {
            tei.append("<TEI xmlns=\"http://www.tei-c.org/ns/1.0\">\n");
        }

        if (doc.getLanguage() != null) {
            tei.append("\t<teiHeader xml:lang=\"" + doc.getLanguage() + "\">");
        } else {
            tei.append("\t<teiHeader>");
        }

        // encodingDesc gives info about the producer of the file
        tei.append("\n\t\t<encodingDesc>\n");
        tei.append("\t\t\t<appInfo>\n");

        TimeZone tz = TimeZone.getTimeZone("UTC");
        DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mmZ");
        df.setTimeZone(tz);
        String dateISOString = df.format(new java.util.Date());

        tei.append("\t\t\t\t<application version=\"" + GrobidProperties.getVersion() +
                "\" ident=\"GROBID\" when=\"" + dateISOString + "\">\n");
        tei.append("\t\t\t\t\t<ref target=\"https://github.com/kermitt2/grobid\">GROBID - A machine learning software for extracting information from scholarly documents</ref>\n");
        tei.append("\t\t\t\t</application>\n");
        tei.append("\t\t\t</appInfo>\n");
        tei.append("\t\t</encodingDesc>");

        tei.append("\n\t\t<fileDesc>\n\t\t\t<titleStmt>\n\t\t\t\t<title level=\"a\" type=\"main\"");
        if (config.isGenerateTeiIds()) {
            String divID = KeyGen.getKey().substring(0, 7);
            tei.append(" xml:id=\"_" + divID + "\"");
        }
        tei.append(">");

        if (biblio == null) {
            // if the biblio object is null, we simply create an empty one
            biblio = new BiblioItem();
        }

        if (biblio.getTitle() != null) {
            tei.append(TextUtilities.HTMLEncode(biblio.getTitle()));
        }

        tei.append("</title>\n\t\t\t</titleStmt>\n");
        if ((biblio.getPublisher() != null) ||
                (biblio.getPublicationDate() != null) ||
                (biblio.getNormalizedPublicationDate() != null)) {
            tei.append("\t\t\t<publicationStmt>\n");
            if (biblio.getPublisher() != null) {
                // publisher and date under <publicationStmt> for better TEI conformance
                tei.append("\t\t\t\t<publisher>" + TextUtilities.HTMLEncode(biblio.getPublisher()) +
                        "</publisher>\n");

                tei.append("\t\t\t\t<availability status=\"unknown\">");
                tei.append("<p>Copyright ");
                //if (biblio.getPublicationDate() != null)
                tei.append(TextUtilities.HTMLEncode(biblio.getPublisher()) + "</p>\n");
                tei.append("\t\t\t\t</availability>\n");
            } else {
                // a dummy publicationStmt is still necessary according to TEI
                tei.append("\t\t\t\t<publisher/>\n");
                if (defaultPublicationStatement == null) {
                    tei.append("\t\t\t\t<availability status=\"unknown\"><licence/></availability>");
                } else {
                    tei.append("\t\t\t\t<availability status=\"unknown\"><p>" +
                            defaultPublicationStatement + "</p></availability>");
                }
                tei.append("\n");
            }

            if (biblio.getNormalizedPublicationDate() != null) {
                Date date = biblio.getNormalizedPublicationDate();
                int year = date.getYear();
                int month = date.getMonth();
                int day = date.getDay();

                String when = "";
                if (year != -1) {
                    if (year <= 9)
                        when += "000" + year;
                    else if (year <= 99)
                        when += "00" + year;
                    else if (year <= 999)
                        when += "0" + year;
                    else
                        when += year;
                    if (month != -1) {
                        if (month <= 9)
                            when += "-0" + month;
                        else
                            when += "-" + month;
                        if (day != -1) {
                            if (day <= 9)
                                when += "-0" + day;
                            else
                                when += "-" + day;
                        }
                    }
                    tei.append("\t\t\t\t<date type=\"published\" when=\"");
                    tei.append(when + "\">");
                } else
                    tei.append("\t\t\t\t<date>");
                if (biblio.getPublicationDate() != null) {
                    tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate()));
                } else {
                    tei.append(when);
                }
                tei.append("</date>\n");
            } else if ((biblio.getYear() != null) && (biblio.getYear().length() > 0)) {
                String when = "";
                if (biblio.getYear().length() == 1)
                    when += "000" + biblio.getYear();
                else if (biblio.getYear().length() == 2)
                    when += "00" + biblio.getYear();
                else if (biblio.getYear().length() == 3)
                    when += "0" + biblio.getYear();
                else if (biblio.getYear().length() == 4)
                    when += biblio.getYear();

                if ((biblio.getMonth() != null) && (biblio.getMonth().length() > 0)) {
                    if (biblio.getMonth().length() == 1)
                        when += "-0" + biblio.getMonth();
                    else
                        when += "-" + biblio.getMonth();
                    if ((biblio.getDay() != null) && (biblio.getDay().length() > 0)) {
                        if (biblio.getDay().length() == 1)
                            when += "-0" + biblio.getDay();
                        else
                            when += "-" + biblio.getDay();
                    }
                }
                tei.append("\t\t\t\t<date type=\"published\" when=\"");
                tei.append(when + "\">");
                if (biblio.getPublicationDate() != null) {
                    tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate()));
                } else {
                    tei.append(when);
                }
                tei.append("</date>\n");
            } else if (biblio.getE_Year() != null) {
                String when = "";
                if (biblio.getE_Year().length() == 1)
                    when += "000" + biblio.getE_Year();
                else if (biblio.getE_Year().length() == 2)
                    when += "00" + biblio.getE_Year();
                else if (biblio.getE_Year().length() == 3)
                    when += "0" + biblio.getE_Year();
                else if (biblio.getE_Year().length() == 4)
                    when += biblio.getE_Year();

                if (biblio.getE_Month() != null) {
                    if (biblio.getE_Month().length() == 1)
                        when += "-0" + biblio.getE_Month();
                    else
                        when += "-" + biblio.getE_Month();

                    if (biblio.getE_Day() != null) {
                        if (biblio.getE_Day().length() == 1)
                            when += "-0" + biblio.getE_Day();
                        else
                            when += "-" + biblio.getE_Day();
                    }
                }
                tei.append("\t\t\t\t<date type=\"ePublished\" when=\"");
                tei.append(when + "\">");
                if (biblio.getPublicationDate() != null) {
                    tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate()));
                } else {
                    tei.append(when);
                }
                tei.append("</date>\n");
            } else if (biblio.getPublicationDate() != null) {
                tei.append("\t\t\t\t<date type=\"published\">");
                tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate())
                        + "</date>");
            }
            tei.append("\t\t\t</publicationStmt>\n");
        } else {
            tei.append("\t\t\t<publicationStmt>\n");
            tei.append("\t\t\t\t<publisher/>\n");
            tei.append("\t\t\t\t<availability status=\"unknown\"><licence/></availability>\n");
            tei.append("\t\t\t</publicationStmt>\n");
        }
        tei.append("\t\t\t<sourceDesc>\n\t\t\t\t<biblStruct>\n\t\t\t\t\t<analytic>\n");

        // authors + affiliation
        //biblio.createAuthorSet();
        //biblio.attachEmails();
        //biblio.attachAffiliations();

        if ( (config.getGenerateTeiCoordinates() != null) && (config.getGenerateTeiCoordinates().contains("persName")) )
            tei.append(biblio.toTEIAuthorBlock(6, true));
        else
            tei.append(biblio.toTEIAuthorBlock(6, false));

        // title
        String title = biblio.getTitle();
        String language = biblio.getLanguage();
        String english_title = biblio.getEnglishTitle();
        if (title != null) {
            tei.append("\t\t\t\t\t\t<title");
            /*if ( (bookTitle == null) & (journal == null) )
                    tei.append(" level=\"m\"");
		    	else */
            tei.append(" level=\"a\" type=\"main\"");

            if (config.isGenerateTeiIds()) {
                String divID = KeyGen.getKey().substring(0, 7);
                tei.append(" xml:id=\"_" + divID + "\"");
            }

            // here check the language ?
            if (english_title == null)
                tei.append(">" + TextUtilities.HTMLEncode(title) + "</title>\n");
            else
                tei.append(" xml:lang=\"" + language + "\">" + TextUtilities.HTMLEncode(title) + "</title>\n");
        }

        boolean hasEnglishTitle = false;
        boolean generateIDs = config.isGenerateTeiIds();
        if (english_title != null) {
            // here do check the language!
            LanguageUtilities languageUtilities = LanguageUtilities.getInstance();
            Language resLang = languageUtilities.runLanguageId(english_title);

            if (resLang != null) {
                String resL = resLang.getLang();
                if (resL.equals(Language.EN)) {
                    hasEnglishTitle = true;
                    tei.append("\t\t\t\t\t\t<title");
                    //if ( (bookTitle == null) & (journal == null) )
                    //	tei.append(" level=\"m\"");
                    //else 
                    tei.append(" level=\"a\"");
                    if (generateIDs) {
                        String divID = KeyGen.getKey().substring(0, 7);
                        tei.append(" xml:id=\"_" + divID + "\"");
                    }
                    tei.append(" xml:lang=\"en\">")
                            .append(TextUtilities.HTMLEncode(english_title)).append("</title>\n");
                }
            }
            // if it's not something in English, we will write it anyway as note without type at the end
        }

        tei.append("\t\t\t\t\t</analytic>\n");

        if ((biblio.getJournal() != null) ||
                (biblio.getJournalAbbrev() != null) ||
                (biblio.getISSN() != null) ||
                (biblio.getISSNe() != null) ||
                (biblio.getPublisher() != null) ||
                (biblio.getPublicationDate() != null) ||
                (biblio.getVolumeBlock() != null) ||
                (biblio.getItem() == BiblioItem.Periodical) ||
                (biblio.getItem() == BiblioItem.InProceedings) ||
                (biblio.getItem() == BiblioItem.Proceedings) ||
                (biblio.getItem() == BiblioItem.InBook) ||
                (biblio.getItem() == BiblioItem.Book) ||
                (biblio.getItem() == BiblioItem.Serie) ||
                (biblio.getItem() == BiblioItem.InCollection)) {
            tei.append("\t\t\t\t\t<monogr");
            tei.append(">\n");

            if (biblio.getJournal() != null) {
                tei.append("\t\t\t\t\t\t<title level=\"j\" type=\"main\"");
                if (generateIDs) {
                    String divID = KeyGen.getKey().substring(0, 7);
                    tei.append(" xml:id=\"_" + divID + "\"");
                }
                tei.append(">" + TextUtilities.HTMLEncode(biblio.getJournal()) + "</title>\n");
            } else if (biblio.getBookTitle() != null) {
                tei.append("\t\t\t\t\t\t<title level=\"m\"");
                if (generateIDs) {
                    String divID = KeyGen.getKey().substring(0, 7);
                    tei.append(" xml:id=\"_" + divID + "\"");
                }
                tei.append(">" + TextUtilities.HTMLEncode(biblio.getBookTitle()) + "</title>\n");
            }

            if (biblio.getJournalAbbrev() != null) {
                tei.append("\t\t\t\t\t\t<title level=\"j\" type=\"abbrev\">" +
                        TextUtilities.HTMLEncode(biblio.getJournalAbbrev()) + "</title>\n");
            }

            if (biblio.getISSN() != null) {
                tei.append("\t\t\t\t\t\t<idno type=\"ISSN\">" +
                        TextUtilities.HTMLEncode(biblio.getISSN()) + "</idno>\n");
            }

            if (biblio.getISSNe() != null) {
                if (!biblio.getISSNe().equals(biblio.getISSN()))
                    tei.append("\t\t\t\t\t\t<idno type=\"eISSN\">" +
                            TextUtilities.HTMLEncode(biblio.getISSNe()) + "</idno>\n");
            }

//            if (biblio.getEvent() != null) {
//                // TODO:
//            }

            // in case the booktitle corresponds to a proceedings, we can try to indicate the meeting title
            String meeting = biblio.getBookTitle();
            boolean meetLoc = false;
            if (biblio.getEvent() != null)
                meeting = biblio.getEvent();
            else if (meeting != null) {
                meeting = meeting.trim();
                for (String prefix : BiblioItem.confPrefixes) {
                    if (meeting.startsWith(prefix)) {
                        meeting = meeting.replace(prefix, "");
                        meeting = meeting.trim();
                        tei.append("\t\t\t\t\t\t<meeting>" + TextUtilities.HTMLEncode(meeting));
                        if ((biblio.getLocation() != null) || (biblio.getTown() != null) ||
                                (biblio.getCountry() != null)) {
                            tei.append(" <address>");
                            if (biblio.getTown() != null) {
                                tei.append("<settlement>" + biblio.getTown() + "</settlement>");
                            }
                            if (biblio.getCountry() != null) {
                                tei.append("<country>" + biblio.getCountry() + "</country>");
                            }
                            if ((biblio.getLocation() != null) && (biblio.getTown() == null) &&
                                    (biblio.getCountry() == null)) {
                                tei.append("<addrLine>" + TextUtilities.HTMLEncode(biblio.getLocation()) + "</addrLine>");
                            }
                            tei.append("</address>\n");
                            meetLoc = true;
                        }
                        tei.append("\t\t\t\t\t\t</meeting>\n");
                        break;
                    }
                }
            }

            if (((biblio.getLocation() != null) || (biblio.getTown() != null) ||
                    (biblio.getCountry() != null))
                    && (!meetLoc)) {
                tei.append("\t\t\t\t\t\t<meeting>");
                tei.append(" <address>");
                if (biblio.getTown() != null) {
                    tei.append(" <settlement>" + biblio.getTown() + "</settlement>");
                }
                if (biblio.getCountry() != null) {
                    tei.append(" <country>" + biblio.getCountry() + "</country>");
                }
                if ((biblio.getLocation() != null) && (biblio.getTown() == null)
                        && (biblio.getCountry() == null)) {
                    tei.append("<addrLine>" + TextUtilities.HTMLEncode(biblio.getLocation()) + "</addrLine>");
                }
                tei.append("</address>\n");
                tei.append("\t\t\t\t\t\t</meeting>\n");
            }

            String pageRange = biblio.getPageRange();

            if ((biblio.getVolumeBlock() != null) | (biblio.getPublicationDate() != null) |
                    (biblio.getNormalizedPublicationDate() != null) |
                    (pageRange != null) | (biblio.getIssue() != null) |
                    (biblio.getBeginPage() != -1) |
                    (biblio.getPublisher() != null)) {
                tei.append("\t\t\t\t\t\t<imprint>\n");

                if (biblio.getPublisher() != null) {
                    tei.append("\t\t\t\t\t\t\t<publisher>" + TextUtilities.HTMLEncode(biblio.getPublisher())
                            + "</publisher>\n");
                }

                if (biblio.getVolumeBlock() != null) {
                    String vol = biblio.getVolumeBlock();
                    vol = vol.replace(" ", "").trim();
                    tei.append("\t\t\t\t\t\t\t<biblScope unit=\"volume\">" +
                            TextUtilities.HTMLEncode(vol) + "</biblScope>\n");
                }

                if (biblio.getIssue() != null) {
                    tei.append("\t\t\t\t\t\t\t<biblScope unit=\"issue\">"
                            + TextUtilities.HTMLEncode(biblio.getIssue()) + "</biblScope>\n");
                }

                if (pageRange != null) {
                    StringTokenizer st = new StringTokenizer(pageRange, "--");
                    if (st.countTokens() == 2) {
                        tei.append("\t\t\t\t\t\t\t<biblScope unit=\"page\"");
                        tei.append(" from=\"" + TextUtilities.HTMLEncode(st.nextToken()) + "\"");
                        tei.append(" to=\"" + TextUtilities.HTMLEncode(st.nextToken()) + "\"/>\n");
                        //tei.append(">" + TextUtilities.HTMLEncode(pageRange) + "</biblScope>\n");
                    } else {
                        tei.append("\t\t\t\t\t\t\t<biblScope unit=\"page\">" + TextUtilities.HTMLEncode(pageRange)
                                + "</biblScope>\n");
                    }
                } else if (biblio.getBeginPage() != -1) {
                    if (biblio.getEndPage() != -1) {
                        tei.append("\t\t\t\t\t\t\t<biblScope unit=\"page\"");
                        tei.append(" from=\"" + biblio.getBeginPage() + "\"");
                        tei.append(" to=\"" + biblio.getEndPage() + "\"/>\n");
                    } else {
                        tei.append("\t\t\t\t\t\t\t<biblScope unit=\"page\"");
                        tei.append(" from=\"" + biblio.getBeginPage() + "\"/>\n");
                    }
                }

                if (biblio.getNormalizedPublicationDate() != null) {
                    Date date = biblio.getNormalizedPublicationDate();
                    int year = date.getYear();
                    int month = date.getMonth();
                    int day = date.getDay();

                    String when = "";
                    if (year != -1) {
                        if (year <= 9)
                            when += "000" + year;
                        else if (year <= 99)
                            when += "00" + year;
                        else if (year <= 999)
                            when += "0" + year;
                        else
                            when += year;
                        if (month != -1) {
                            if (month <= 9)
                                when += "-0" + month;
                            else
                                when += "-" + month;
                            if (day != -1) {
                                if (day <= 9)
                                    when += "-0" + day;
                                else
                                    when += "-" + day;
                            }
                        }
                        if (biblio.getPublicationDate() != null) {
                            tei.append("\t\t\t\t\t\t\t<date type=\"published\" when=\"");
                            tei.append(when + "\">");
                            tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate())
                                    + "</date>\n");
                        } else {
                            tei.append("\t\t\t\t\t\t\t<date type=\"published\" when=\"");
                            tei.append(when + "\" />\n");
                        }
                    } else {
                        if (biblio.getPublicationDate() != null) {
                            tei.append("\t\t\t\t\t\t\t<date type=\"published\">");
                            tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate())
                                    + "</date>\n");
                        }
                    }
                } else if (biblio.getYear() != null) {
                    String when = "";
                    if (biblio.getYear().length() == 1)
                        when += "000" + biblio.getYear();
                    else if (biblio.getYear().length() == 2)
                        when += "00" + biblio.getYear();
                    else if (biblio.getYear().length() == 3)
                        when += "0" + biblio.getYear();
                    else if (biblio.getYear().length() == 4)
                        when += biblio.getYear();

                    if (biblio.getMonth() != null) {
                        if (biblio.getMonth().length() == 1)
                            when += "-0" + biblio.getMonth();
                        else
                            when += "-" + biblio.getMonth();
                        if (biblio.getDay() != null) {
                            if (biblio.getDay().length() == 1)
                                when += "-0" + biblio.getDay();
                            else
                                when += "-" + biblio.getDay();
                        }
                    }
                    if (biblio.getPublicationDate() != null) {
                        tei.append("\t\t\t\t\t\t\t<date type=\"published\" when=\"");
                        tei.append(when + "\">");
                        tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate())
                                + "</date>\n");
                    } else {
                        tei.append("\t\t\t\t\t\t\t<date type=\"published\" when=\"");
                        tei.append(when + "\" />\n");
                    }
                } else if (biblio.getE_Year() != null) {
                    String when = "";
                    if (biblio.getE_Year().length() == 1)
                        when += "000" + biblio.getE_Year();
                    else if (biblio.getE_Year().length() == 2)
                        when += "00" + biblio.getE_Year();
                    else if (biblio.getE_Year().length() == 3)
                        when += "0" + biblio.getE_Year();
                    else if (biblio.getE_Year().length() == 4)
                        when += biblio.getE_Year();

                    if (biblio.getE_Month() != null) {
                        if (biblio.getE_Month().length() == 1)
                            when += "-0" + biblio.getE_Month();
                        else
                            when += "-" + biblio.getE_Month();

                        if (biblio.getE_Day() != null) {
                            if (biblio.getE_Day().length() == 1)
                                when += "-0" + biblio.getE_Day();
                            else
                                when += "-" + biblio.getE_Day();
                        }
                    }
                    tei.append("\t\t\t\t\t\t\t<date type=\"ePublished\" when=\"");
                    tei.append(when + "\" />\n");
                } else if (biblio.getPublicationDate() != null) {
                    tei.append("\t\t\t\t\t\t\t<date type=\"published\">");
                    tei.append(TextUtilities.HTMLEncode(biblio.getPublicationDate())
                            + "</date>\n");
                }

                // Fix for issue #31
                tei.append("\t\t\t\t\t\t</imprint>\n");
            }
            tei.append("\t\t\t\t\t</monogr>\n");
        } else {
            tei.append("\t\t\t\t\t<monogr>\n");
            tei.append("\t\t\t\t\t\t<imprint>\n");
            tei.append("\t\t\t\t\t\t\t<date/>\n");
            tei.append("\t\t\t\t\t\t</imprint>\n");
            tei.append("\t\t\t\t\t</monogr>\n");
        }

        if (biblio.getDOI() != null) {
            String theDOI = TextUtilities.HTMLEncode(biblio.getDOI());
            if (theDOI.endsWith(".xml")) {
                theDOI = theDOI.replace(".xml", "");
            }

            tei.append("\t\t\t\t\t<idno type=\"DOI\">" + theDOI + "</idno>\n");
        }

        if (biblio.getSubmission() != null) {
            tei.append("\t\t\t\t\t<note type=\"submission\">" +
                    TextUtilities.HTMLEncode(biblio.getSubmission()) + "</note>\n");
        }

        if (biblio.getDedication() != null) {
            tei.append("\t\t\t\t\t<note type=\"dedication\">" + TextUtilities.HTMLEncode(biblio.getDedication())
                    + "</note>\n");
        }

        if ((english_title != null) & (!hasEnglishTitle)) {
            tei.append("\t\t\t\t\t<note type=\"title\"");
            if (generateIDs) {
                String divID = KeyGen.getKey().substring(0, 7);
                tei.append(" xml:id=\"_" + divID + "\"");
            }
            tei.append(">" + TextUtilities.HTMLEncode(english_title) + "</note>\n");
        }

        if (biblio.getNote() != null) {
            tei.append("\t\t\t\t\t<note");
            if (generateIDs) {
                String divID = KeyGen.getKey().substring(0, 7);
                tei.append(" xml:id=\"_" + divID + "\"");
            }
            tei.append(">" + TextUtilities.HTMLEncode(biblio.getNote()) + "</note>\n");
        }

        tei.append("\t\t\t\t</biblStruct>\n");

        if (biblio.getURL() != null) {
            tei.append("\t\t\t\t<ref target=\"" + biblio.getURL() + "\" />\n");
        }

        tei.append("\t\t\t</sourceDesc>\n");
        tei.append("\t\t</fileDesc>\n");

        boolean textClassWritten = false;

        tei.append("\t\t<profileDesc>\n");

        // keywords here !! Normally the keyword field has been preprocessed
        // if the segmentation into individual keywords worked, the first conditional
        // statement will be used - otherwise the whole keyword field is outputed
        if ((biblio.getKeywords() != null) && (biblio.getKeywords().size() > 0)) {
            textClassWritten = true;
            tei.append("\t\t\t<textClass>\n");
            tei.append("\t\t\t\t<keywords>\n");

            List<Keyword> keywords = biblio.getKeywords();
            int pos = 0;
            for (Keyword keyw : keywords) {
                if ((keyw.getKeyword() == null) || (keyw.getKeyword().length() == 0))
                    continue;
                String res = keyw.getKeyword().trim();
                if (res.startsWith(":")) {
                    res = res.substring(1);
                }
                if (pos == (keywords.size() - 1)) {
                    if (res.endsWith(".")) {
                        res = res.substring(0, res.length() - 1);
                    }
                }
                tei.append("\t\t\t\t\t<term");
                if (generateIDs) {
                    String divID = KeyGen.getKey().substring(0, 7);
                    tei.append(" xml:id=\"_" + divID + "\"");
                }
                tei.append(">" + TextUtilities.HTMLEncode(res) + "</term>\n");
                pos++;
            }
            tei.append("\t\t\t\t</keywords>\n");
        } else if (biblio.getKeyword() != null) {
            String keywords = biblio.getKeyword();
            textClassWritten = true;
            tei.append("\t\t\t<textClass>\n");
            tei.append("\t\t\t\t<keywords");

            if (generateIDs) {
                String divID = KeyGen.getKey().substring(0, 7);
                tei.append(" xml:id=\"_" + divID + "\"");
            }
            tei.append(">");
            tei.append(TextUtilities.HTMLEncode(biblio.getKeyword())).append("</keywords>\n");
        }

        if (biblio.getCategories() != null) {
            if (!textClassWritten) {
                textClassWritten = true;
                tei.append("\t\t\t<textClass>\n");
            }
            List<String> categories = biblio.getCategories();
            tei.append("\t\t\t\t<keywords>");
            for (String category : categories) {
                tei.append("\t\t\t\t\t<term");
                if (generateIDs) {
                    String divID = KeyGen.getKey().substring(0, 7);
                    tei.append(" xml:id=\"_" + divID + "\"");
                }
                tei.append(">" + TextUtilities.HTMLEncode(category.trim()) + "</term>\n");
            }
            tei.append("\t\t\t\t</keywords>\n");
        }

        if (textClassWritten)
            tei.append("\t\t\t</textClass>\n");

        String abstractText = biblio.getAbstract();

        Language resLang = null;
        if (abstractText != null) {
            LanguageUtilities languageUtilities = LanguageUtilities.getInstance();
            resLang = languageUtilities.runLanguageId(abstractText);
        }
        if (resLang != null) {
            String resL = resLang.getLang();
            if (!resL.equals(doc.getLanguage())) {
                tei.append("\t\t\t<abstract xml:lang=\"").append(resL).append("\">\n");
            } else {
                tei.append("\t\t\t<abstract>\n");
            }
        } else if ((abstractText == null) || (abstractText.length() == 0)) {
            tei.append("\t\t\t<abstract/>\n");
        } else {
            tei.append("\t\t\t<abstract>\n");
        }

        if ((abstractText != null) && (abstractText.length() != 0)) {
            /*String abstractHeader = biblio.getAbstractHeader();
            if (abstractHeader == null)
                abstractHeader = "Abstract";
            tei.append("\t\t\t\t<head");
			if (generateIDs) {
				String divID = KeyGen.getKey().substring(0,7);
				tei.append(" xml:id=\"_" + divID + "\"");
			}
			tei.append(">").append(TextUtilities.HTMLEncode(abstractHeader)).append("</head>\n");*/

            tei.append("\t\t\t\t<p");
            if (generateIDs) {
                String divID = KeyGen.getKey().substring(0, 7);
                tei.append(" xml:id=\"_" + divID + "\"");
            }
            tei.append(">").append(TextUtilities.HTMLEncode(abstractText)).append("</p>\n");

            tei.append("\t\t\t</abstract>\n");
        }

        tei.append("\t\t</profileDesc>\n");

        if ((biblio.getA_Year() != null) |
                (biblio.getS_Year() != null) |
                (biblio.getSubmissionDate() != null) |
                (biblio.getNormalizedSubmissionDate() != null)
                ) {
            tei.append("\t\t<revisionDesc>\n");
        }

        // submission and other review dates here !
        if (biblio.getA_Year() != null) {
            String when = biblio.getA_Year();
            if (biblio.getA_Month() != null) {
                when += "-" + biblio.getA_Month();
                if (biblio.getA_Day() != null) {
                    when += "-" + biblio.getA_Day();
                }
            }
            tei.append("\t\t\t\t<date type=\"accepted\" when=\"");
            tei.append(when).append("\" />\n");
        }
        if (biblio.getNormalizedSubmissionDate() != null) {
            Date date = biblio.getNormalizedSubmissionDate();
            int year = date.getYear();
            int month = date.getMonth();
            int day = date.getDay();

            String when = "" + year;
            if (month != -1) {
                when += "-" + month;
                if (day != -1) {
                    when += "-" + day;
                }
            }
            tei.append("\t\t\t\t<date type=\"submission\" when=\"");
            tei.append(when).append("\" />\n");
        } else if (biblio.getS_Year() != null) {
            String when = biblio.getS_Year();
            if (biblio.getS_Month() != null) {
                when += "-" + biblio.getS_Month();
                if (biblio.getS_Day() != null) {
                    when += "-" + biblio.getS_Day();
                }
            }
            tei.append("\t\t\t\t<date type=\"submission\" when=\"");
            tei.append(when).append("\" />\n");
        } else if (biblio.getSubmissionDate() != null) {
            tei.append("\t\t\t<date type=\"submission\">")
                    .append(TextUtilities.HTMLEncode(biblio.getSubmissionDate())).append("</date>\n");

            /*tei.append("\t\t\t<change when=\"");
            tei.append(TextUtilities.HTMLEncode(biblio.getSubmissionDate()));
			tei.append("\">Submitted</change>\n");
			*/
        }
        if ((biblio.getA_Year() != null) |
                (biblio.getS_Year() != null) |
                (biblio.getSubmissionDate() != null)
                ) {
            tei.append("\t\t</revisionDesc>\n");
        }

        tei.append("\t</teiHeader>\n");

        if (doc.getLanguage() != null) {
            tei.append("\t<text xml:lang=\"").append(doc.getLanguage()).append("\">\n");
        } else {
            tei.append("\t<text>\n");
        }

        return tei;
    }


    /**
     * TEI formatting of the body where only basic logical document structures are present.
     * This TEI format avoids most of the risks of ill-formed TEI due to structure recognition
     * errors and frequent PDF noises.
     * It is adapted to fully automatic process and simple exploitation of the document structures
     * like structured indexing and search.
     */
    public StringBuilder toTEIBody(StringBuilder buffer,
                                   String result,
                                   BiblioItem biblio,
                                   List<BibDataSet> bds,
                                   LayoutTokenization layoutTokenization,
                                   List<Figure> figures,
                                   List<Table> tables,
                                   List<Equation> equations,
                                   Document doc,
                                   GrobidAnalysisConfig config) throws Exception {
        if ((result == null) || (layoutTokenization == null) || (layoutTokenization.getTokenization() == null)) {
            buffer.append("\t\t<body/>\n");
            return buffer;
        }
        buffer.append("\t\t<body>\n");
        buffer = toTEITextPiece(buffer, result, biblio, bds,
                layoutTokenization, figures, tables, equations, doc, config);

        // notes are still in the body
        buffer = toTEINote(buffer, doc, config);

        buffer.append("\t\t</body>\n");

        return buffer;
    }

    private StringBuilder toTEINote(StringBuilder tei,
                                    Document doc,
                                    GrobidAnalysisConfig config) throws Exception {
        // write the notes
        SortedSet<DocumentPiece> documentNoteParts = doc.getDocumentPart(SegmentationLabels.FOOTNOTE);
        if (documentNoteParts != null) {
            tei = toTEINote("foot", documentNoteParts, tei, doc, config);
        }
        documentNoteParts = doc.getDocumentPart(SegmentationLabels.MARGINNOTE);
        if (documentNoteParts != null) {
            tei = toTEINote("margin", documentNoteParts, tei, doc, config);
        }
        return tei;
    }

    private StringBuilder toTEINote(String noteType,
                                    SortedSet<DocumentPiece> documentNoteParts,
                                    StringBuilder tei,
                                    Document doc,
                                    GrobidAnalysisConfig config) throws Exception {
        List<String> allNotes = new ArrayList<String>();
        for (DocumentPiece docPiece : documentNoteParts) {
            String footText = doc.getDocumentPieceText(docPiece);
            footText = TextUtilities.dehyphenize(footText);
            footText = footText.replace("\n", " ");
            footText = footText.replace("  ", " ").trim();
            if (footText.length() < 6)
                continue;
            if (allNotes.contains(footText)) {
                // basically we have here the "recurrent" headnote/footnote for each page,
                // no need to add them several times (in the future we could even use them
                // differently combined with the header)
                continue;
            }
            // pattern is <note n="1" place="foot" xml:id="no1">
            tei.append("\n\t\t\t<note place=\""+noteType+"\"");
            Matcher ma = startNum.matcher(footText);
            int currentNumber = -1;
            if (ma.find()) {
                String groupStr = ma.group(1);
                footText = ma.group(2);
                try {
                    currentNumber = Integer.parseInt(groupStr);
                } catch (NumberFormatException e) {
                    currentNumber = -1;
                }
            }
            if (currentNumber != -1) {
                tei.append(" n=\"" + currentNumber + "\"");
            }
            if (config.isGenerateTeiIds()) {
                String divID = KeyGen.getKey().substring(0, 7);
                tei.append(" xml:id=\"_" + divID + "\"");
            }
            tei.append(">");
            tei.append(TextUtilities.HTMLEncode(footText));
            allNotes.add(footText);
            tei.append("</note>\n");
        }

        return tei;
    }

    public StringBuilder toTEIAcknowledgement(StringBuilder buffer,
                                              String reseAcknowledgement,
                                              List<LayoutToken> tokenizationsAcknowledgement,
                                              List<BibDataSet> bds,
                                              GrobidAnalysisConfig config) throws Exception {
        if ((reseAcknowledgement == null) || (tokenizationsAcknowledgement == null)) {
            return buffer;
        }

        buffer.append("\n\t\t\t<div type=\"acknowledgement\">\n");
        StringBuilder buffer2 = new StringBuilder();

        buffer2 = toTEITextPiece(buffer2, reseAcknowledgement, null, bds,
                new LayoutTokenization(tokenizationsAcknowledgement), null, null, null, doc, config);
        String acknowResult = buffer2.toString();
        String[] acknowResultLines = acknowResult.split("\n");
        boolean extraDiv = false;
        if (acknowResultLines.length != 0) {
            for (int i = 0; i < acknowResultLines.length; i++) {
                if (acknowResultLines[i].trim().length() == 0)
                    continue;
                buffer.append(TextUtilities.dehyphenize(acknowResultLines[i]) + "\n");
            }
        }
        buffer.append("\t\t\t</div>\n\n");

        return buffer;
    }


    public StringBuilder toTEIAnnex(StringBuilder buffer,
                                    String result,
                                    BiblioItem biblio,
                                    List<BibDataSet> bds,
                                    List<LayoutToken> tokenizations,
                                    Document doc,
                                    GrobidAnalysisConfig config) throws Exception {
        if ((result == null) || (tokenizations == null)) {
            return buffer;
        }

        buffer.append("\t\t\t<div type=\"annex\">\n");
        buffer = toTEITextPiece(buffer, result, biblio, bds,
                new LayoutTokenization(tokenizations), null, null, null, doc, config);
        buffer.append("\t\t\t</div>\n");

        return buffer;
    }

    private StringBuilder toTEITextPiece(StringBuilder buffer,
                                         String result,
                                         BiblioItem biblio,
                                         List<BibDataSet> bds,
                                         LayoutTokenization layoutTokenization,
                                         List<Figure> figures,
                                         List<Table> tables,
                                         List<Equation> equations,
                                         Document doc,
                                         GrobidAnalysisConfig config) throws Exception {
        TaggingLabel lastClusterLabel = null;
//System.out.println(result);
        int startPosition = buffer.length();

        //boolean figureBlock = false; // indicate that a figure or table sequence was met
        // used for reconnecting a paragraph that was cut by a figure/table

        List<LayoutToken> tokenizations = layoutTokenization.getTokenization();

        TaggingTokenClusteror clusteror = new TaggingTokenClusteror(GrobidModels.FULLTEXT, result, tokenizations);

        String tokenLabel = null;
        List<TaggingTokenCluster> clusters = clusteror.cluster();

        List<Element> divResults = new ArrayList<>();

        Element curDiv = teiElement("div");
        Element curParagraph = null;
        int equationIndex = 0; // current equation index position 
        for (TaggingTokenCluster cluster : clusters) {
            if (cluster == null) {
                continue;
            }

            TaggingLabel clusterLabel = cluster.getTaggingLabel();
            Engine.getCntManager().i(clusterLabel);

            String clusterContent = LayoutTokensUtil.normalizeText(LayoutTokensUtil.toText(cluster.concatTokens()));
            if (clusterLabel.equals(TaggingLabels.SECTION)) {
                curDiv = teiElement("div");
                Element head = teiElement("head");
                // section numbers
                Pair<String, String> numb = getSectionNumber(clusterContent);
                if (numb != null) {
                    head.addAttribute(new Attribute("n", numb.b));
                    head.appendChild(numb.a);
                } else {
                    head.appendChild(clusterContent);
                }
                curDiv.appendChild(head);
                divResults.add(curDiv);
            } else if (clusterLabel.equals(TaggingLabels.EQUATION) || 
                    clusterLabel.equals(TaggingLabels.EQUATION_LABEL)) {
                // get starting position of the cluster
                int start = -1;
                if ( (cluster.concatTokens() != null) && (cluster.concatTokens().size() > 0) ) {
                    start = cluster.concatTokens().get(0).getOffset();
                }
                // get the corresponding equation
                if (start != -1) {
                    Equation theEquation = null;
                    if (equations != null) {
                        for(int i=0; i<equations.size(); i++) {
                            if (i < equationIndex) 
                                continue;
                            Equation equation = equations.get(i);
                            if (equation.getStart() == start) {
                                theEquation = equation;
                                equationIndex = i;
                                break;
                            }
                        }
                        if (theEquation != null) {
                            Element element = theEquation.toTEIElement(config);
                            if (element != null)
                                curDiv.appendChild(element);
                        }
                    }
                }
            } else if (clusterLabel.equals(TaggingLabels.ITEM)) {
                curDiv.appendChild(teiElement("item", clusterContent));
            } else if (clusterLabel.equals(TaggingLabels.OTHER)) {
                Element note = teiElement("note", clusterContent);
                note.addAttribute(new Attribute("type", "other"));
                curDiv.appendChild(note);
            } else if (clusterLabel.equals(TaggingLabels.PARAGRAPH)) {
                if (isNewParagraph(lastClusterLabel, curParagraph)) {
                    curParagraph = teiElement("p");
                    curDiv.appendChild(curParagraph);
                }
                curParagraph.appendChild(clusterContent);
            } else if (MARKER_LABELS.contains(clusterLabel)) {
                List<LayoutToken> refTokens = cluster.concatTokens();
                String chunkRefString = LayoutTokensUtil.toText(refTokens);
                Element parent = curParagraph != null ? curParagraph : curDiv;
                parent.appendChild(new Text(" "));

                List<Node> refNodes;
                if (clusterLabel.equals(TaggingLabels.CITATION_MARKER)) {
                    refNodes = markReferencesTEILuceneBased(chunkRefString,
                            refTokens,
                            doc.getReferenceMarkerMatcher(),
                            config.isGenerateTeiCoordinates("ref"));

                } else if (clusterLabel.equals(TaggingLabels.FIGURE_MARKER)) {
                    refNodes = markReferencesFigureTEI(chunkRefString, refTokens, figures,
                            config.isGenerateTeiCoordinates("ref"));
                } else if (clusterLabel.equals(TaggingLabels.TABLE_MARKER)) {
                    refNodes = markReferencesTableTEI(chunkRefString, refTokens, tables,
                            config.isGenerateTeiCoordinates("ref"));
                } else if (clusterLabel.equals(TaggingLabels.EQUATION_MARKER)) {
                    refNodes = markReferencesEquationTEI(chunkRefString, refTokens, equations,
                            config.isGenerateTeiCoordinates("ref"));                    
                } else {
                    throw new IllegalStateException("Unsupported marker type: " + clusterLabel);
                }

                if (refNodes != null) {
                    for (Node n : refNodes) {
                        parent.appendChild(n);
                    }
                }
            } else if (clusterLabel.equals(TaggingLabels.FIGURE) || clusterLabel.equals(TaggingLabels.TABLE)) {
                //figureBlock = true;
                if (curParagraph != null)
                    curParagraph.appendChild(new Text(" "));
            }

            lastClusterLabel = cluster.getTaggingLabel();
        }

        buffer.append(XmlBuilderUtils.toXml(divResults));

        // we apply some overall cleaning and simplification
        buffer = TextUtilities.replaceAll(buffer, "</head><head",
                "</head>\n\t\t\t</div>\n\t\t\t<div>\n\t\t\t\t<head");
        buffer = TextUtilities.replaceAll(buffer, "</p>\t\t\t\t<p>", " ");

        //TODO: work on reconnection
        // we evaluate the need to reconnect paragraphs cut by a figure or a table
        int indP1 = buffer.indexOf("</p0>", startPosition - 1);
        while (indP1 != -1) {
            int indP2 = buffer.indexOf("<p>", indP1 + 1);
            if ((indP2 != 1) && (buffer.length() > indP2 + 5)) {
                if (Character.isUpperCase(buffer.charAt(indP2 + 4)) &&
                        Character.isLowerCase(buffer.charAt(indP2 + 5))) {
                    // a marker for reconnecting the two paragraphs
                    buffer.setCharAt(indP2 + 1, 'q');
                }
            }
            indP1 = buffer.indexOf("</p0>", indP1 + 1);
        }
        buffer = TextUtilities.replaceAll(buffer, "</p0>(\\n\\t)*<q>", " ");
        buffer = TextUtilities.replaceAll(buffer, "</p0>", "</p>");
        buffer = TextUtilities.replaceAll(buffer, "<q>", "<p>");

        if (figures != null) {
            for (Figure figure : figures) {
                String figSeg = figure.toTEI(config);
                if (figSeg != null) {
                    buffer.append(figSeg).append("\n");
                }
            }
        }
        if (tables != null) {
            for (Table table : tables) {
                String tabSeg = table.toTEI(config);
                if (tabSeg != null) {
                    buffer.append(tabSeg).append("\n");
                }
            }
        }

        return buffer;
    }

    private boolean isNewParagraph(TaggingLabel lastClusterLabel, Element curParagraph) {
        return (!MARKER_LABELS.contains(lastClusterLabel) && lastClusterLabel != TaggingLabels.FIGURE
                && lastClusterLabel != TaggingLabels.TABLE) || curParagraph == null;
    }


    /**
     * Return the graphic objects in a given interval position in the document.
     */
    private List<GraphicObject> getGraphicObject(List<GraphicObject> graphicObjects, int startPos, int endPos) {
        List<GraphicObject> result = new ArrayList<GraphicObject>();
        for (GraphicObject nto : graphicObjects) {
            if ((nto.getStartPosition() >= startPos) && (nto.getStartPosition() <= endPos)) {
                result.add(nto);
            }
            if (nto.getStartPosition() > endPos) {
                break;
            }
        }
        return result;
    }

    private Pair<String, String> getSectionNumber(String text) {
        Matcher m1 = BasicStructureBuilder.headerNumbering1.matcher(text);
        Matcher m2 = BasicStructureBuilder.headerNumbering2.matcher(text);
        Matcher m3 = BasicStructureBuilder.headerNumbering3.matcher(text);
        Matcher m = null;
        String numb = null;
        if (m1.find()) {
            numb = m1.group(0);
            m = m1;
        } else if (m2.find()) {
            numb = m2.group(0);
            m = m2;
        } else if (m3.find()) {
            numb = m3.group(0);
            m = m3;
        }
        if (numb != null) {
            text = text.replace(numb, "").trim();
            numb = numb.replace(" ", "");
            return new Pair<>(text, numb);
        } else {
            return null;
        }
    }

    public StringBuilder toTEIReferences(StringBuilder tei,
                                         List<BibDataSet> bds,
                                         GrobidAnalysisConfig config) throws Exception {
        tei.append("\t\t\t<div type=\"references\">\n\n");

        if ((bds == null) || (bds.size() == 0))
            tei.append("\t\t\t\t<listBibl/>\n");
        else {
            tei.append("\t\t\t\t<listBibl>\n");

            int p = 0;
            if (bds.size() > 0) {
                for (BibDataSet bib : bds) {
                    BiblioItem bit = bib.getResBib();
                    if (bit != null) {
                        tei.append("\n" + bit.toTEI(p, 0, config));
                    } else {
                        tei.append("\n");
                    }
                    p++;
                }
            }
            tei.append("\n\t\t\t\t</listBibl>\n");
        }
        tei.append("\t\t\t</div>\n");

        return tei;
    }


    //bounding boxes should have already been calculated when calling this method
    public static String getCoordsAttribute(List<BoundingBox> boundingBoxes, boolean generateCoordinates) {
        if (!generateCoordinates || boundingBoxes == null || boundingBoxes.isEmpty()) {
            return "";
        }
        String coords = Joiner.on(";").join(boundingBoxes);
        return "coords=\"" + coords + "\"";
    }

    /**
     * DEPRECATED: use markReferencesTEILuceneBased instead
     * Mark using TEI annotations the identified references in the text body build with the machine learning model.
     */
    public String markReferencesTEI(String text, List<LayoutToken> refTokens,
                                    List<BibDataSet> bds, boolean generateCoordinates) {
        // safety tests
        if (text == null)
            return null;
        if (text.trim().length() == 0)
            return text;
        if (text.endsWith("</ref>") || text.startsWith("<ref"))
            return text;

        CntManager cntManager = Engine.getCntManager();

        text = TextUtilities.HTMLEncode(text);
        boolean numerical = false;

        String coords = null;
        if (generateCoordinates)
            coords = LayoutTokensUtil.getCoordsString(refTokens);
        if (coords == null) {
            coords = "";
        } else {
            coords = "coords=\"" + coords + "\"";
        }
        // we check if we have numerical references

        // we re-write compact references, i.e [1,2] -> [1] [2]
        //
        String relevantText = bracketReferenceSegment(text);
        if (relevantText != null) {
            Matcher m2 = numberRefCompact.matcher(text);
            StringBuffer sb = new StringBuffer();
            boolean result = m2.find();
            // Loop through and create a new String
            // with the replacements
            while (result) {
                String toto = m2.group(0);
                if (toto.contains("]")) {
                    toto = toto.replace(",", "] [");
                    toto = toto.replace("[ ", "[");
                    toto = toto.replace(" ]", "]");
                } else {
                    toto = toto.replace(",", ") (");
                    toto = toto.replace("( ", "(");
                    toto = toto.replace(" )", ")");
                }
                m2.appendReplacement(sb, toto);
                result = m2.find();
            }
            // Add the last segment of input to
            // the new String
            m2.appendTail(sb);
            text = sb.toString();

            // we expend the references [1-3] -> [1] [2] [3]
            Matcher m3 = numberRefCompact2.matcher(text);
            StringBuffer sb2 = new StringBuffer();
            boolean result2 = m3.find();
            // Loop through and create a new String
            // with the replacements
            while (result2) {
                String toto = m3.group(0);
                if (toto.contains("]")) {
                    toto = toto.replace("]", "");
                    toto = toto.replace("[", "");
                    int ind = toto.indexOf('-');
                    if (ind == -1)
                        ind = toto.indexOf('\u2013');
                    if (ind != -1) {
                        try {
                            int firstIndex = Integer.parseInt(toto.substring(0, ind));
                            int secondIndex = Integer.parseInt(toto.substring(ind + 1, toto.length()));
                            // how much values can we expend? We use a ratio of the total number of references
                            // with a minimal value
                            int maxExpend = 10 + (bds.size() / 10);
                            if (secondIndex - firstIndex > maxExpend) {
                                break;
                            }
                            toto = "";
                            boolean first = true;
                            for (int j = firstIndex; j <= secondIndex; j++) {
                                if (first) {
                                    toto += "[" + j + "]";
                                    first = false;
                                } else
                                    toto += " [" + j + "]";
                            }
                        } catch (Exception e) {
                            throw new GrobidException("An exception occurs.", e);
                        }
                    }
                } else {
                    toto = toto.replace(")", "");
                    toto = toto.replace("(", "");
                    int ind = toto.indexOf('-');
                    if (ind == -1)
                        ind = toto.indexOf('\u2013');
                    if (ind != -1) {
                        try {
                            int firstIndex = Integer.parseInt(toto.substring(0, ind));
                            int secondIndex = Integer.parseInt(toto.substring(ind + 1, toto.length()));
                            if (secondIndex - firstIndex > 9) {
                                break;
                            }
                            toto = "";
                            boolean first = true;
                            for (int j = firstIndex; j <= secondIndex; j++) {
                                if (first) {
                                    toto += "(" + j + ")";
                                    first = false;
                                } else
                                    toto += " (" + j + ")";
                            }
                        } catch (Exception e) {
                            throw new GrobidException("An exception occurs.", e);
                        }
                    }
                }
                m3.appendReplacement(sb2, toto);
                result2 = m3.find();
            }
            // Add the last segment of input to
            // the new String
            m3.appendTail(sb2);
            text = sb2.toString();
        }
        int p = 0;
        if ((bds != null) && (bds.size() > 0)) {
            for (BibDataSet bib : bds) {
                List<String> contexts = bib.getSourceBib();
                String marker = TextUtilities.HTMLEncode(bib.getRefSymbol());
                BiblioItem resBib = bib.getResBib();

                if (resBib != null) {
                    // try first to match the reference marker string with marker (label) present in the
                    // bibliographical section
                    if (marker != null) {
                        Matcher m = numberRef.matcher(marker);
                        int ind = -1;
                        if (m.find()) {
                            ind = text.indexOf(marker);
                        } else {
                            // possibly the marker in the biblio section is simply a number, and used
                            // in the ref. with brackets - so we also try this case
                            m = numberRef.matcher("[" + marker + "]");
                            if (m.find()) {
                                ind = text.indexOf("[" + marker + "]");
                                if (ind != -1) {
                                    marker = "[" + marker + "]";
                                }
                            }

                        }
                        if (ind != -1) {
                            text = text.substring(0, ind) +
                                    "<ref type=\"bibr\" target=\"#b" + p + "\" " + coords + ">" + marker
                                    + "</ref>" + text.substring(ind + marker.length(), text.length());
                            cntManager.i(ReferenceMarkerMatcherCounters.MATCHED_REF_MARKERS);
                        }
                    }

                    // search for first author, date and possibly second author
                    String author1 = resBib.getFirstAuthorSurname();
                    String author2 = null;
                    if (author1 != null) {
                        author1 = author1.toLowerCase();
                    }
                    String year = null;
                    Date datt = resBib.getNormalizedPublicationDate();
                    if (datt != null) {
                        if (datt.getYear() != -1) {
                            year = "" + datt.getYear();
                        }
                    }
                    char extend1 = 0;
                    // we check if we have an identifier with the year (e.g. 2010b)
                    if (resBib.getPublicationDate() != null) {
                        String dat = resBib.getPublicationDate();
                        if (year != null) {
                            int ind = dat.indexOf(year);
                            if (ind != -1) {
                                if (ind + year.length() < dat.length()) {
                                    extend1 = dat.charAt(ind + year.length());
                                }
                            }
                        }
                    }

                    List<Person> fullAuthors = resBib.getFullAuthors();
                    if (fullAuthors != null) {
                        int nbAuthors = fullAuthors.size();
                        if (nbAuthors == 2) {
                            // we get the last name of the second author
                            author2 = fullAuthors.get(1).getLastName();
                        }
                    }
                    if (author2 != null) {
                        author2 = author2.toLowerCase();
                    }

                    // try to match based on the author and year strings
                    if ((author1 != null) && (year != null)) {
                        int indi1; // first author
                        int indi2; // year
                        int indi3 = -1; // second author if only two authors in total
                        int i = 0;
                        boolean end = false;

                        while (!end) {
                            indi1 = text.toLowerCase().indexOf(author1, i); // first author matching
                            indi2 = text.indexOf(year, i); // year matching
                            int added = 1;
                            if (author2 != null) {
                                indi3 = text.toLowerCase().indexOf(author2, i); // second author matching
                            }
                            char extend2 = 0;
                            if (indi2 != -1) {
                                if (text.length() > indi2 + year.length()) {
                                    extend2 = text.charAt(indi2 + year.length()); // (e.g. 2010b)
                                }
                            }

                            if ((indi1 == -1) || (indi2 == -1)) {
                                end = true;
                                // no author has been found, we go on with the next biblio item
                            } else if ((indi1 != -1) && (indi2 != -1) && (indi3 != -1) && (indi1 < indi2) &&
                                    (indi1 < indi3) && (indi2 - indi1 > author1.length())) {
                                // this is the case with 2 authors in the marker

                                if ((extend1 != 0) && (extend2 != 0) && (extend1 != extend2)) {
                                    end = true;
                                    // we have identifiers with the year, but they don't match
                                    // e.g. 2010a != 2010b
                                } else {
                                    // we check if we don't have another instance of the author between the two indices
                                    int indi1bis = text.toLowerCase().indexOf(author1, indi1 + author1.length());
                                    if (indi1bis == -1) {
                                        String reference = text.substring(indi1, indi2 + 4);
                                        boolean extended = false;
                                        if (text.length() > indi2 + 4) {
                                            if ((text.charAt(indi2 + 4) == ')') ||
                                                    (text.charAt(indi2 + 4) == ']') ||
                                                    ((extend1 != 0) && (extend2 != 0) && (extend1 == extend2))) {
                                                reference += text.charAt(indi2 + 4);
                                                extended = true;
                                            }
                                        }
                                        String previousText = text.substring(0, indi1);
                                        String followingText = "";
                                        if (extended) {
                                            followingText = text.substring(indi2 + 5, text.length());
                                            // 5 digits for the year + identifier character
                                            text = "<ref type=\"bibr\" target=\"#b" + p + "\" " + coords + ">" + reference + "</ref>";
                                            cntManager.i(ReferenceMarkerMatcherCounters.MATCHED_REF_MARKERS);
                                            added = 8;

                                        } else {
                                            followingText = text.substring(indi2 + 4, text.length());
                                            // 4 digits for the year
                                            text = "<ref type=\"bibr\" target=\"#b" + p + "\" " + coords + ">" + reference + "</ref>";
                                            cntManager.i(ReferenceMarkerMatcherCounters.MATCHED_REF_MARKERS);
                                            added = 7;
                                        }
                                        if (previousText.length() > 2) {
                                            previousText =
                                                    markReferencesTEI(previousText, refTokens, bds,
                                                            generateCoordinates);
                                        }
                                        if (followingText.length() > 2) {
                                            followingText =
                                                    markReferencesTEI(followingText, refTokens, bds,
                                                            generateCoordinates);
                                        }

                                        return previousText + text + followingText;
                                    }
                                    end = true;
                                }
                            } else if ((indi1 != -1) && (indi2 != -1) && (indi1 < indi2) &&
                                    (indi2 - indi1 > author1.length())) {
                                // this is the case with 1 author in the marker

                                if ((extend1 != 0) && (extend2 != 0) && (extend1 != extend2)) {
                                    end = true;
                                } else {
                                    // we check if we don't have another instance of the author between the two indices
                                    int indi1bis = text.toLowerCase().indexOf(author1, indi1 + author1.length());
                                    if (indi1bis == -1) {
                                        String reference = text.substring(indi1, indi2 + 4);
                                        boolean extended = false;
                                        if (text.length() > indi2 + 4) {
                                            if ((text.charAt(indi2 + 4) == ')') ||
                                                    (text.charAt(indi2 + 4) == ']') ||
                                                    ((extend1 != 0) && (extend2 != 0) & (extend1 == extend2))) {
                                                reference += text.charAt(indi2 + 4);
                                                extended = true;
                                            }
                                        }
                                        String previousText = text.substring(0, indi1);
                                        String followingText = "";
                                        if (extended) {
                                            followingText = text.substring(indi2 + 5, text.length());
                                            // 5 digits for the year + identifier character
                                            text = "<ref type=\"bibr\" target=\"#b" + p + "\" " + coords + ">" + reference + "</ref>";
                                            cntManager.i(ReferenceMarkerMatcherCounters.MATCHED_REF_MARKERS);
                                            added = 8;
                                        } else {
                                            followingText = text.substring(indi2 + 4, text.length());
                                            // 4 digits for the year
                                            text = "<ref type=\"bibr\" target=\"#b" + p + "\" " + coords + ">" + reference + "</ref>";
                                            cntManager.i(ReferenceMarkerMatcherCounters.MATCHED_REF_MARKERS);
                                            added = 7;
                                        }
                                        if (previousText.length() > 2) {
                                            previousText =
                                                    markReferencesTEI(previousText, refTokens, bds,
                                                            generateCoordinates);
                                        }
                                        if (followingText.length() > 2) {
                                            followingText =
                                                    markReferencesTEI(followingText, refTokens, bds,
                                                            generateCoordinates);
                                        }

                                        return previousText + text + followingText;
                                    }
                                    end = true;
                                }
                            }
                            i = indi2 + year.length() + added;
                            if (i >= text.length()) {
                                end = true;
                            }
                        }
                    }
                }
                p++;
            }
        }

        // we have not been able to solve the bibliographical marker, but we still annotate it globally
        // without pointer - just ignoring possible punctuation at the beginning and end of the string
        if (!text.endsWith("</ref>") && !text.startsWith("<ref"))
            text = "<ref type=\"bibr\">" + text + "</ref>";
        cntManager.i(ReferenceMarkerMatcherCounters.UNMATCHED_REF_MARKERS);
        return text;
    }

    /**
     * Identify in a reference string the part in bracket. Return null if no opening and closing bracket
     * can be found.
     */
    public static String bracketReferenceSegment(String text) {
        int ind1 = text.indexOf("(");
        if (ind1 == -1)
            ind1 = text.indexOf("[");
        if (ind1 != -1) {
            int ind2 = text.lastIndexOf(")");
            if (ind2 == -1)
                ind2 = text.lastIndexOf("]");
            if ((ind2 != -1) && (ind1 < ind2)) {
                return text.substring(ind1, ind2 + 1);
            }
        }
        return null;
    }

    /**
     * Mark using TEI annotations the identified references in the text body build with the machine learning model.
     */
    public List<Node> markReferencesTEILuceneBased(String text, List<LayoutToken> refTokens,
                                                   ReferenceMarkerMatcher markerMatcher, boolean generateCoordinates) throws EntityMatcherException {
        // safety tests
        if (text == null || text.trim().length() == 0 || text.endsWith("</ref>") || text.startsWith("<ref"))
            return Collections.<Node>singletonList(new Text(text));
        
        boolean spaceEnd = false;
        text = text.replace("\n", " ");
        if (text.endsWith(" "))
            spaceEnd = true;

        List<Node> nodes = new ArrayList<>();
        for (ReferenceMarkerMatcher.MatchResult matchResult : markerMatcher.match(refTokens)) {
            // no need to HTMLEncode since XOM will take care about the correct escaping
            String markerText = LayoutTokensUtil.normalizeText(matchResult.getText());
            String coords = null;
            if (generateCoordinates && matchResult.getTokens() != null) {
                coords = LayoutTokensUtil.getCoordsString(matchResult.getTokens());
            }

            Element ref = teiElement("ref");
            ref.addAttribute(new Attribute("type", "bibr"));

            if (coords != null) {
                ref.addAttribute(new Attribute("coords", coords));
            }
            ref.appendChild(markerText);

            if (matchResult.getBibDataSet() != null) {
                ref.addAttribute(new Attribute("target", "#b" + matchResult.getBibDataSet().getResBib().getOrdinal()));
            }
            nodes.add(ref);
        }
        if (spaceEnd)
            nodes.add(new Text(" "));
        return nodes;
    }


    public List<Node> markReferencesFigureTEI(String text, 
                                            List<LayoutToken> refTokens,
                                            List<Figure> figures,
                                            boolean generateCoordinates) {
        if (text == null || text.trim().isEmpty()) {
            return null;
        }

        List<Node> nodes = new ArrayList<>();

        String textLow = text.toLowerCase();
        String bestFigure = null;

        if (figures != null) {
            for (Figure figure : figures) {
                if ((figure.getLabel() != null) && (figure.getLabel().length() > 0)) {
                    String label = TextUtilities.cleanField(figure.getLabel(), false);
                    if ((label.length() > 0) &&
                            (textLow.contains(label.toLowerCase()))) {
                        bestFigure = figure.getId();
                        break;
                    }
                }
            }
        }

        boolean spaceEnd = false;
        text = text.replace("\n", " ");
        if (text.endsWith(" "))
            spaceEnd = true;
        text = text.trim();

        String coords = null;
        if (generateCoordinates && refTokens != null) {
            coords = LayoutTokensUtil.getCoordsString(refTokens);
        }

        Element ref = teiElement("ref");
        ref.addAttribute(new Attribute("type", "figure"));

        if (coords != null) {
            ref.addAttribute(new Attribute("coords", coords));
        }
        ref.appendChild(text);

        if (bestFigure != null) {
            ref.addAttribute(new Attribute("target", "#fig_" + bestFigure));
        }
        nodes.add(ref);
        if (spaceEnd)
            nodes.add(new Text(" "));
        return nodes;
    }

    public List<Node> markReferencesTableTEI(String text, List<LayoutToken> refTokens,
                                             List<Table> tables,
                                             boolean generateCoordinates) {
        if (text == null || text.trim().isEmpty()) {
            return null;
        }

        List<Node> nodes = new ArrayList<>();

        String textLow = text.toLowerCase();
        String bestTable = null;
        if (tables != null) {
            for (Table table : tables) {
                /*if ((table.getId() != null) &&
                        (table.getId().length() > 0) &&
                        (textLow.contains(table.getId().toLowerCase()))) {
                    bestTable = table.getId();
                    break;
                }*/
                if ((table.getLabel() != null) && (table.getLabel().length() > 0)) {
                    String label = TextUtilities.cleanField(table.getLabel(), false);
                    if ((label.length() > 0) &&
                            (textLow.contains(label.toLowerCase()))) {
                        bestTable = table.getId();
                        break;
                    }
                }
            }
        }

        boolean spaceEnd = false;
        text = text.replace("\n", " ");
        if (text.endsWith(" "))
            spaceEnd = true;
        text = text.trim();

        String coords = null;
        if (generateCoordinates && refTokens != null) {
            coords = LayoutTokensUtil.getCoordsString(refTokens);
        }

        Element ref = teiElement("ref");
        ref.addAttribute(new Attribute("type", "table"));

        if (coords != null) {
            ref.addAttribute(new Attribute("coords", coords));
        }
        ref.appendChild(text);
        if (bestTable != null) {
            ref.addAttribute(new Attribute("target", "#tab_" + bestTable));
        }
        nodes.add(ref);
        if (spaceEnd)
            nodes.add(new Text(" "));
        return nodes;
    }

    public List<Node> markReferencesEquationTEI(String text, 
                                            List<LayoutToken> refTokens,
                                            List<Equation> equations,
                                            boolean generateCoordinates) {
        if (text == null || text.trim().isEmpty()) {
            return null;
        }

        List<Node> nodes = new ArrayList<>();

        String textLow = text.toLowerCase();
        String bestFormula = null;
        if (equations != null) {
            for (Equation equation : equations) {
                if ((equation.getLabel() != null) && (equation.getLabel().length() > 0)) {
                    String label = TextUtilities.cleanField(equation.getLabel(), false);
                    if ((label.length() > 0) &&
                            (textLow.contains(label.toLowerCase()))) {
                        bestFormula = equation.getId();
                        break;
                    }
                }
            }
        }
        
        boolean spaceEnd = false;
        text = text.replace("\n", " ");
        if (text.endsWith(" "))
            spaceEnd = true;
        text = text.trim();

        String coords = null;
        if (generateCoordinates && refTokens != null) {
            coords = LayoutTokensUtil.getCoordsString(refTokens);
        }

        Element ref = teiElement("ref");
        ref.addAttribute(new Attribute("type", "formula"));

        if (coords != null) {
            ref.addAttribute(new Attribute("coords", coords));
        }
        ref.appendChild(text);
        if (bestFormula != null) {
            ref.addAttribute(new Attribute("target", "#formula_" + bestFormula));
        }
        nodes.add(ref);
        if (spaceEnd)
            nodes.add(new Text(" "));
        return nodes;
    }

    private String normalizeText(String localText) {
        localText = localText.trim();
        localText = TextUtilities.dehyphenize(localText);
        localText = localText.replace("\n", " ");
        localText = localText.replace("  ", " ");

        return localText.trim();
    }
}