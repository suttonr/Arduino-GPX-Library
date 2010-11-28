/*
 * GPX Library -- GPX.h
 * Created by: Ryan Sutton
 *
 * Changelog:
 * 11/25/10 -- RMS -- Created Library
 */

#ifndef GPX_h
#define GPX_h

#include <WProgram.h>
#include <WString.h>

#define _GPX_HEAD "<gpx version=\"1.1\" creator=\"Arduino GPX Lib\"\n xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n xmlns=\"http://www.topografix.com/GPX/1/1\"\n xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\"\n>\n"
#define _GPX_TAIL               "</gpx>\n"
#define _GPX_META_HEAD          "<metadata>"
#define _GPX_META_TAIL          "</metadata>\n"
#define _GPX_TRAK_HEAD          "<trk>"
#define _GPX_TRAK_TAIL          "</trk>\n"
#define _GPX_TRKSEG_HEAD        "<trkseg>"
#define _GPX_TRKSEG_TAIL        "</trkseg>\n"
#define _GPX_PT_HEAD            "<TYPE lat=\""
#define _GPX_PT_TAIL            "</TYPE>\n"

// Property Tags
#define _GPX_NAME_HEAD          "<name>"
#define _GPX_NAME_TAIL          "</name>\n"
#define _GPX_DESC_HEAD          "<desc>"
#define _GPX_DESC_TAIL          "</desc>\n"
#define _GPX_SYM_HEAD           "<sym>"
#define _GPX_SYM_TAIL           "</sym>\n"
#define _GPX_ELE_HEAD           "<ele>"
#define _GPX_ELE_TAIL           "</ele>\n"
#define _GPX_SRC_HEAD           "<src>"
#define _GPX_SRC_TAIL           "</src>\n"
#define _GPX_TIME_HEAD          "<time>"
#define _GPX_TIME_TAIL          "</time>\n"

// 'Public' Tags
#define GPX_TRKPT               "trkpt"
#define GPX_WPT                 "wpt"
#define GPX_RTEPT               "rtept"

class GPX{
  public:
    GPX();
    String getOpen();
    String getClose();
    String getMetaData();
    String getTrakOpen();
    String getTrakClose();
    String getTrakSegOpen();
    String getTrakSegClose();
    String getInfo();
    String getPt(String typ, String lon, String lat);
    String getPt(String typ, String lon, String lat, String ele);
    void setMetaName(String name);
    void setMetaDesc(String desc);
    void setName(String name);
    void setDesc(String desc);
    void setEle(String ele);
    void setSym(String sym);
    void setSrc(String src);
    void setTime(String time);
  private:
    //Variables
    String _metaName;
    String _metaDesc;
    String _name;
    String _desc;
    String _ele;
    String _sym;
    String _src;
    String _time;

    //Functions
    String wrapCDATA(String input);
};

#endif

