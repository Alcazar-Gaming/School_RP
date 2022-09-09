#include <a_samp>

/*
    School System - Stewart

    Required libs:
    MySQL - https://github.com/pBlueG/SA-MP-MySQL/releases/tag/R39-6
    Pawn.CMD - https://github.com/katursis/Pawn.CMD/releases/tag/3.3.6
    sscanf - https://github.com/Y-Less/sscanf/releases/tag/v2.13.2

    NOTE: On Line 75(Full Details). :)
*/

#include <a_mysql>
#include <Pawn.CMD>
#include <sscanf2>

#define SCHOOL_NAME         ""// Change nyo nalang to sa kung anong school name gusto nyo

// Adding SQL for solo Alpha Test
#define SQL_HOST            ""
#define SQL_DB              ""
#define SQL_USER            ""
#define SQL_PASS            ""
new MySQL;
new query[2000];

#define COLOR_WHITE         0xFFFFFFFF
#define COLOR_BLUE          0x0000FFFF
#define COLOR_YELLOW        0xFFFF00FF
#define COLOR_GREEN         0x00FF00FF
#define COLOR_AQUA          0x00FFFFFF

new students;
new teachers;

enum schEnum{
    schStudent,
    schTeacher,
    schGraduated
}
new SchoolInfo[MAX_PLAYERS][schEnum];

main(){}

public OnGameModeInit(){
    MySQL = mysql_connect(SQL_HOST, SQL_USER, SQL_DB, SQL_PASS);
    if(mysql_errno()){
        printf("We cannot connect you to the databse(%s) right now. Double check your MySQL config, and try again.", SQL_DB);
        SendRconCommand("exit");
        return 0;
    }
    else{
        printf("Successfully connected to the database %s.", SQL_DB);
    }
    return 1;
}

public OnGameModeExit(){

    return 1;
}

public OnPlayerConnect(playerid){
    // Just in case it'll reset and will not be passed to another player who logged in and on the player id on the player who logged out.
    SchoolInfo[playerid][schStudent] = 0;
    SchoolInfo[playerid][schTeacher] = 0;
    SchoolInfo[playerid][schGraduated] = 0;
    return 1;
}

// Non-Static Callbacks

// Details on note above.
// Add this to your player load callback/thread for the server to load player's school stats.
// format(query, sizeof(query), "SELECT * FROM dbschool WHERE name = '%s'", GetUserName(playerid));
// 'mysql_tquery(MySQL, , "LoadSchoolDB", "i", playerid);'
forward LoadSchoolDB(playerid);
public LoadSchoolDB(playerid){
    if(cache_num_rows()){
        SchoolInfo[playerid][schStudent] = cache_get_field_content_int(0, "student");
        SchoolInfo[playerid][schTeacher] = cache_get_field_content_int(0, "teacher");
        SchoolInfo[playerid][schGraduated] = cache_get_field_content_int(0, "graduated");
    }
}

// Other Declarations //

GetUserName(playerid){
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, MAX_PLAYER_NAME);

    for(new i = 0; i < strlen(name); i ++){
        if(name[i] == '_') name[i] = ' ';
    }
    return name;
}

// - Stocks //

stock ShowSchoolStats(playerid){
    new title[128], string[200];
    format(title, 128, "%s's School Statistics", GetUserName(playerid));
    if(SchoolInfo[playerid][schTeacher] != 1){
        format(string, sizeof(string), "School Rank: Student\nTeacher: %s", SchoolInfo[playerid][Teacher]);
        ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, title, string, "Close", "");
    }
    else{
        format(string, sizeof(string), "School Rank: Teacher\nStudents: %i", students);
        ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, title, string, "Close", "");
    }
}

CMD:school(playerid, params[]){
    if(SchoolInfo[playerid][schTeacher] > 0){
        new option[30], param[128];
        if(sscanf(params, "s[30]S()[128]", option, param)){
            return SendClientMessage(playerid, COLOR_WHITE, "Usage: /school [option] (diploma/enroll)");
        }

        if(!strcmp(option, "diploma", true)){
            new macc[20], id;
            if(sscanf(param, "s[20]i", macc, id)){
                SendClientMessage(playerid, COLOR_WHITE, "Usage: /school [diploma] [option] [id]");
                SendClientMessage(playerid, COLOR_YELLOW, "[OPTIONS]: {FFFFFF}revoke/set");
                return 1;
            }
            if(!IsPlayerConnected(id)) return SendClientMessage(playerid, COLOR_WHITE, "The ID you entered is not online.");

            if(!strcmp(macc, "set", true)){
                new message[128];
                SchoolInfo[id][schGraduated] = 1;
                format(message, 128, "[SCHOOL]: {FFFFFF}You have been gruadated and approved by teacher %s. Congratulations!!!", GetUserName(playerid));
                SendClientMessage(playerid, COLOR_AQUA, message);
                return 1;
            }
            else if(!strcmp(macc, "revoke", true)){
                new message[128];
                SchoolInfo[id][schGraduated] = 0;
                format(message, 128, "[SCHOOL]: {FFFFFF}Your diploma has been revoked by teacher %s", GetUserName(playerid));
                SendClientMessage(playerid, COLOR_AQUA, message);
                return 1;
            }
        }
        else if(!strcmp(option, "enroll", true)){
            new id, message[128];
            if(sscanf(param, "i", id)){
                SendClientMessage(playerid, COLOR_WHITE, "Usage: /school [enroll] [id]");
                return 1;
            }
            if(!IsPlayerConnected(id)) return SendClientMessage(playerid, COLOR_WHITE, "The ID you entered is not online.");

            SchoolInfo[id][schStudent] = 1;
            format(message, 128, "[SCHOOL]: {FFFFFF}You have been enrolled to %s by teacher %s. Congratulations!!!", SCHOOL_NAME, GetUserName(playerid));
            SendClientMessage(playerid, COLOR_AQUA, message);
            return 1;
        }
    }
    return 1;
}

CMD:setteacher(playerid, params[]){
    new id;
    if(sscanf(params, "i", id)){
        SendClientMessage(playerid, COLOR_WHITE, "Usage: /setteacher [id]");
        return 1;
    }
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, COLOR_WHITE, "The ID you entered is not online.");
    if(SchoolInfo[id][schTeacher] == 1) return SendClientMessage(playerid, COLOR_WHITE, "The ID you entered is already a teacher.");

    SchoolInfo[id][schTeacher] = 1;
    format(query, sizeof(query), "UPDATE dbschool SET teacher = 1 WHERE name = '%s'", GetUserName(playerid));
    mysql_tquery(MySQL, query);
        
    new mess[128], mess1[128];
    format(mess, 128, "[SCHOOL]: {FFFFFF}You have been set as teacher by %s.", GetUserName(playerid));
    format(mess1, 128, "[SCHOOL]: {FFFFFF}You have set %s as teacher.", GetUserName(id));
    SendClientMessage(id, COLOR_AQUA, mess);
    SendClientMessage(playerid, COLOR_AQUA, mess1);
    return 1;
}