**free
dcl-f syscheck workstn indds(dsInds);    

dcl-pi *n;
    returnValues char(1); // If 'Y' don't use workstation files
    parmLastUpdated char(26);
    parmDasdCur zoned(6:4);
    parmDasd5MinAgo zoned(6:4);
    parmDasdToday zoned(6:4);
    parmCpuCur zoned(3:1);
    parmCpu5MinAgo zoned(3:1);
    parmCpuToday zoned(3:1);
end-pi;

// Indicators for F-keys from the display file
dcl-ds dsInds len(99);
  F3 ind pos(3);
  F5 ind pos(5);
  F6 ind pos(6);
end-ds;

// Data Area Specs
dcl-ds SYSSTS dtaara('*LIBL/SYSCHECK') len(59) qualified;
    dasdCur Char(7);
    dasd5MinAgo Char(7);
    dasdToday Char(7);
    cpuCur Char(4);
    cpu5MinAgo Char(4);
    cpuToday Char(4);
    lastUpdated Char(26);
end-ds;

dcl-s hasError Char(1) INZ ('N');

if (%parms = 0 OR returnValues <> 'Y');
    
    // Default display
    DASDCUR = 'N/A';
    DASD5 = 'N/A';
    DASDSOD = 'N/A';
    CPUCUR = 'N/A';
    CPU5 = 'N/A';
    CPUSOD = 'N/A';
    LASTUPD = 'N/A';
    MESSAGE = '';
    
    // Write header & footer
    write header;
    write footer;
    
    // Input loop
    dow (1 = 1);
        // Update header for timestamp update
        write header;
        
        // Clear workstation message and error status
        hasError = 'N';
        MESSAGE = '';
        
        if (F3 = *On);
            leave;
        elseif (F6 = *ON);
            exfmt about;
            
            // Footer is intentionally overwritten
            write footer;
        else;
            // Default to update status and display
            updateStatus();
            
            if (hasError = 'N');
                in SYSSTS;
            
                // Current
                if (SYSSTS.dasdCur = *BLANKS);
                    DASDCUR = 'N/A';
                else;
                    DASDCUR = SYSSTS.dasdCur + '%';
                endif;
                if (SYSSTS.cpuCur = *BLANKS);
                    CPUCUR = 'N/A';
                else;
                    CPUCUR = SYSSTS.cpuCur + '%';
                endif;
                
                // 5 Min Ago
                if (SYSSTS.dasd5MinAgo = *BLANKS);
                    DASD5 = 'N/A';
                else;
                    DASD5 = SYSSTS.dasd5MinAgo + '%';
                endif;
                if (SYSSTS.cpu5MinAgo = *BLANKS);
                    CPU5 = 'N/A';
                else;
                    CPU5 = SYSSTS.cpu5MinAgo + '%';
                endif;
                
                // Start of Day
                if (SYSSTS.dasdToday = *BLANKS);
                    DASDSOD = 'N/A';
                else;
                    DASDSOD = SYSSTS.dasdToday + '%';
                endif;
                if (SYSSTS.cpuToday = *BLANKS);
                    CPUSOD = 'N/A';
                else;
                    CPUSOD = SYSSTS.cpuToday + '%';
                endif;
                
                // Last Updated
                if (SYSSTS.lastUpdated = *BLANKS);
                    LASTUPD = 'N/A';
                else;
                    LASTUPD = SYSSTS.lastUpdated;
                endif;
            endif;
            
            // Update data and read input
            exfmt data;
        endif;
    enddo;

elseif (%parms > 1 AND returnValues = 'Y');

    updateStatus();

    in SYSSTS;

    // Current
    if (SYSSTS.dasdCur = *BLANKS);
        parmDasdCur = -1;
    else;
        parmDasdCur = %Dec(SYSSTS.dasdCur:6:4);
    endif;
    if (SYSSTS.cpuCur = *BLANKS);
        parmCpuCur = -1;
    else;
        parmCpuCur = %Dec(SYSSTS.cpuCur:3:1);
    endif;
    
    // 5 Min Ago
    if (SYSSTS.dasd5MinAgo = *BLANKS);
        parmDasd5MinAgo = -1;
    else;
        parmDasd5MinAgo = %Dec(SYSSTS.dasd5MinAgo:6:4);
    endif;
    if (SYSSTS.cpu5MinAgo = *BLANKS);
        parmCpu5MinAgo = -1;
    else;
        parmCpu5MinAgo = %Dec(SYSSTS.cpu5MinAgo:3:1);
    endif;
    
    // Start of Day
    if (SYSSTS.dasdToday = *BLANKS);
        parmDasdToday = -1;
    else;
        parmDasdToday = %Dec(SYSSTS.dasdToday:6:4);
    endif;
    if (SYSSTS.cpuToday = *BLANKS);
        parmCpuToday = -1;
    else;
        parmCpuToday = %Dec(SYSSTS.cpuToday:3:1);
    endif;
    
    // Last Updated
    if (SYSSTS.lastUpdated = *BLANKS);
        parmLastUpdated = 'N/A';
    else;
        parmLastUpdated = SYSSTS.lastUpdated;
    endif;
endif;

*inlr = *On;

return;

// Sub-procedure that calls WQCRSSTS and updates the data area with new information
dcl-proc updateStatus;
    
    // Information for QWCRSSTS API Call
    dcl-s format Char(8) INZ('SSTS0200');
    dcl-s RecieverLen Int(10) INZ(57);
    dcl-s resetStats Char(10) INZ('*NO');
    
    // API Return Datastruture (aka the info we care about)
    dcl-ds API_Ret qualified;
        PctSystemASPUsed Int(10) Pos(53);
        PctSystemCPUUsed Int(10) Pos(33);
    end-ds;
    
    // API Error Datastructure
    dcl-ds API_Err qualified;
        ErrBytes Int(10);
        ErrBytesAva BinDec(8);
        Exception Char(7);
        Reserved Char(1);
        Data Char(255);
    end-ds;
        
    // Prototype & Procedure interfaces
    dcl-pr QWCRSSTS extpgm;
      Reviever LikeDS(API_Ret);
      RecieverLen Int(10);
      FormatName Char(8);
      ResetStatusStats Char(10);
      ErrorCode LikeDS(API_Err);
    end-pr;
    
    // Temp vars
    dcl-s currentTime Timestamp;
    dcl-s lastUpdated Timestamp;
    dcl-s currentDASD Char(7);
    dcl-s currentCPU  Char(4);
    
    // MAIN
    MONITOR; // Monitors for 0431, locked DTAARA
        callp QWCRSSTS(API_ret : recieverLen : format : resetStats : API_Err);
        
        // Verify we wont overflow anything
        if (API_ret.PctSystemCPUUsed / 10 > 100);
            API_ret.PctSystemCPUUsed = 99.9 * 10;
        endif;
        
        currentDASD = %Char(API_ret.PctSystemASPUsed / 10000);
        currentCPU = %Char(API_ret.PctSystemCPUUsed / 10);
        
        // Pull in Data Area information
        in SYSSTS;
        currentTime = %timestamp();
        
        // Verify we're not overflowing anything
        
        // Initialize Data Area if needed
        if (SYSSTS.lastUpdated = *BLANKS);
            in *lock SYSSTS;
            SYSSTS.dasdCur = currentDASD;
            SYSSTS.cpuCur = currentCPU;
            SYSSTS.lastUpdated = %Char(currentTime);
            out SYSSTS;
        endif;
        
        // Update current day (if it's a new day)
        lastUpdated = %timestamp(SYSSTS.lastUpdated);
        if (%diff(currentTime : lastUpdated : *DAYS) >= 1);
            in *lock SYSSTS;
            SYSSTS.dasdToday = currentDASD;
            SYSSTS.cpuToday = currentCPU;
            out SYSSTS;
        endif;
        
        // Update Timestamps 
        if (%diff(currentTime : lastUpdated : *MINUTES) >= 5);
            in *lock SYSSTS;
            SYSSTS.lastUpdated = %Char(currentTime);
            SYSSTS.dasd5MinAgo = SYSSTS.dasdCur;
            SYSSTS.dasdCur = currentDASD;
            SYSSTS.cpu5MinAgo = SYSSTS.cpuCur;
            SYSSTS.cpuCur = currentCPU;
            out SYSSTS;
        endif;
        
    on-error 401;
        MESSAGE = '        Data area *LIBL/SYSCHECK not found';
        hasError = 'Y';
    on-error 411;
        MESSAGE = '    Data area *LIBL/SYSCHECK should be len(54)';
        hasError = 'Y';
    on-error 431;
        // Don't care
    ENDMON;
end-proc;