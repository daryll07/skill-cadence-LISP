;pcb_checklist.il
;Master Checklist Wizard - Dashboard V26 (Ultra-Compact Horizontal Layout)

axlCmdRegister("pcb_check" 'launch_pcb_checklist)

procedure( pcb_load_report_scripts()
  let((root)
    root = axlOSSlash(getWorkingDir())
    when(isFile(strcat(root "/r1_log.il"))  errset(load(strcat(root "/r1_log.il"))  t))
    when(isFile(strcat(root "/r2_log.il"))  errset(load(strcat(root "/r2_log.il"))  t))
    when(isFile(strcat(root "/r3_log.il"))  errset(load(strcat(root "/r3_log.il"))  t))
    when(isFile(strcat(root "/r4_log.il"))  errset(load(strcat(root "/r4_log.il"))  t))
    when(isFile(strcat(root "/r5_log.il"))  errset(load(strcat(root "/r5_log.il"))  t))
    when(isFile(strcat(root "/r6_log.il"))  errset(load(strcat(root "/r6_log.il"))  t))
    when(isFile(strcat(root "/r7_log.il"))  errset(load(strcat(root "/r7_log.il"))  t))
    when(isFile(strcat(root "/r8_log.il"))  errset(load(strcat(root "/r8_log.il"))  t))
    when(isFile(strcat(root "/r9_log.il"))  errset(load(strcat(root "/r9_log.il"))  t))
    when(isFile(strcat(root "/r10_log.il")) errset(load(strcat(root "/r10_log.il")) t))
	when(isFile(strcat(root "/r11_log.il")) errset(load(strcat(root "/r11_log.il")) t))
  )
)

;; --- 1-LINER TRUNCATOR ---
procedure( pcb_truncate_desc(txt max_len)
    let((clean_txt)
        clean_txt = buildString(parseString(txt "\n\r\t") " ")
        clean_txt = buildString(parseString(clean_txt "\"") "'")
        if(strlen(clean_txt) > max_len then
            strcat(substring(clean_txt 1 max_len-3) "...")
        else
            clean_txt
        )
    )
)

;; --- TEXT WRAPPER FOR THE DETAILS BOX ---
procedure( pcb_split_lines(txt max_width)
    prog((raw_lines final_lines words cur_line)
        raw_lines = parseString(txt "\n")
        final_lines = nil
        foreach(rl raw_lines
            words = parseString(rl " ")
            cur_line = ""
            foreach(w words
                if(cur_line == "" then
                    cur_line = w
                else
                    if(strlen(cur_line) + strlen(w) + 1 > max_width then
                        final_lines = cons(cur_line final_lines)
                        cur_line = w
                    else
                        cur_line = strcat(cur_line " " w)
                    )
                )
            )
            if(cur_line != "" then final_lines = cons(cur_line final_lines))
        )
        return(reverse(final_lines))
    )
)

;; --- THE AUTO-FETCHER ---
procedure( pcb_fetch_var(target_var)
  let((found_val target_upper aliases all_objs obj props p p_name p_val p_str key)
    found_val = ""
    target_upper = upperCase(target_var)
    aliases = list(target_upper)
	
    when(target_upper == "MODEL"
      aliases = append(aliases '("PCB_MODEL"))
	)
    when(target_upper == "PARTNUMBER"
      aliases = append(aliases '("PCB_PN" "PN" "PARTNUMBER" "PART_NO" "DWG_NO"))
    )
    when(target_upper == "REV"
      aliases = append(aliases '("PCB_REV" "REVISION" "REV"))
    )
    when(target_upper == "TITLE"
       aliases = append(aliases '("PCB_DESC" "DESCRIPTION" "DESC" "TITLE"))
    )
    when(target_upper == "ASSYDRAWINGNUMBER"
      aliases = append(aliases '("PCB_ASSYPN" "ASSYPN" "ASSY_NO" "ASSY_DWG" "ASSY"))
    )
    when(target_upper == "BOARDTHICKNESS"
      aliases = append(aliases '("PCB_THICK" "PCB_THICKNESS" "THICKNESS" "THK" "BOARDTHICKNESS" "BOARD_THICKNESS"))
    )

    axlClearSelSet()
    axlSetFindFilter(?enabled '("noall" "shapes" "text" "symbols") ?onButtons '("noall" "shapes" "text" "symbols"))
    axlAddSelectAll()
    all_objs = cons(axlDBGetDesign() axlGetSelSet())
    axlClearSelSet()

    foreach(obj all_objs
      when(found_val == ""
        props = nil
        errset(props = axlDBGetProperties(obj "user") t)
        when(!props errset(props = axlDBGetProperties(obj) t))

        when(props
          foreach(p props
            when(found_val == ""
              if(listp(p) then p_name = car(p) p_val  = cadr(p)
              else p_name = p p_val  = nil errset(p_val = axlDBGetProperty(obj p_name) t))

              when(p_name
                let((name_u val_s)
                  name_u = upperCase(sprintf(nil "%s" p_name))
                  val_s  = if(p_val sprintf(nil "%s" p_val) "")

                  foreach(key aliases
                    when(found_val == "" && name_u == key && val_s != "" found_val = val_s)
                    when(found_val == "" && (name_u == strcat("AET_CUSTOMVARNAME_" key)) && val_s != "" found_val = val_s)
                  )
                  when(found_val == "" && val_s != ""
                    p_str = sprintf(nil "%s" val_s)
                    foreach(key aliases
                      when(found_val == "" && rexMatchp(strcat(key "=") upperCase(p_str))
                        let((parts)
                          parts = parseString(p_str "=\n\r\t,;")
                          for(i 0 length(parts)-2
                            when(upperCase(buildString(parseString(nth(i parts) " ") "")) == key
                              found_val = nth(i+1 parts)
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
    
    if(found_val == "" && (target_upper == "BOARDTHICKNESS" || target_upper == "THICKNESS") then
        let((dsgn_param)
            errset(dsgn_param = axlGetParam("paramDesign") t)
            if(dsgn_param && dsgn_param->thickness then
                found_val = sprintf(nil "%g" dsgn_param->thickness)
            )
        )
    )

    if(found_val != "" then buildString(parseString(found_val "\"") "") else "")
  )
)

;; 1. Master Data Structure
(setq pcb_chk_data '(
    ("Report" "R-1" "Distance of Press-fit components to board edge is 2.3mm." command "r1_log" nil)
	("Report" "R-2" "Double check hole to PCB edge distance." command "r2_log" nil)
    ("Report" "R-3" "Properties on Nets Report." command "r3_log" nil)
    ("Report" "R-4" "Net Short Properties Report." command "r4_log" nil)
    ("Report" "R-5" "Net Single pin and No Pin." command "r5_log" nil)
    ("Report" "R-6" "Verify with DE of all pin with no nets (Dummy Pins)." command "r6_log" nil)    
    ("Report" "R-7" "Netlist Report." command "r7_log" nil)
    ("Report" "R-8" "Unconnected Pins Report." command "r8_log" nil)
    ("Report" "R-9" "Unplaced Component Report. Check for design stage." command "r9_log" nil)
    ("Report" "R-10" "Unused Blind/Buried Via Report." command "r10_log" nil)
    ("Report" "R-11" "Waived Design Rules Check Report." command "r11_log" nil)

    ("DRC-1" "DRC-1" "Create separate board file for running Valor and uploading for MVR." comment nil nil)
    ("DRC-1" "DRC-2" "Double check location of DATUM (0,0)." comment nil nil)
    ("DRC-1" "DRC-3" "SMT components, fiducial mark must be added." comment nil nil)
    ("DRC-1" "DRC-4" "Double check symbol versions based on Valor." comment nil nil)
    ("DRC-1" "DRC-5" "Mounting hole details on .dxf must have complete details." comment nil nil)
	("DRC-1" "DRC-6" "Double check any metal object that will land or go near on board that might possibly cause safety spacing concern." comment nil nil)
    ("DRC-1" "DRC-7" "Place Tooling holes for ICT Testing." comment nil nil)
    ("DRC-1" "DRC-8" "Double check SMT component to Solder wave pins on solder side. Refer to section 4.5.4.3.1 of 920-000253-0000." comment nil nil)
	("DRC-1" "DRC-9" "NO traces and via under optocoupler." comment nil nil)
	
	("DRC-2" "DRC-10" "Double check alignment and location of manually added soldermask openings." comment nil nil)
	("DRC-2" "DRC-11" "Vias must not overlap with solder paste." comment nil nil)
	("DRC-2" "DRC-12" "Double check and fix any bad pad entry." comment nil nil)
    ("DRC-2" "DRC-13" "Always use standard thermal relief pattern." comment nil nil)
    ("DRC-2" "DRC-14" "Add copper layer marking." comment nil nil)
    ("DRC-2" "DRC-15" "Consider Fiducial_mark and CU layer marking as dead metal." comment nil nil)
	
    ("DRC-3" "DRC-16" "Check and include additional silkscreen markings listed as below:" checkbox nil nil 
        ("1.) Project TLA, Board PN, Board name" 
         "2.) Date Code (8888)" 
         "3.) Lead Free logo (for PCB with Lead Free HASL surface finish)" 
         "4.) WSD Marking (for PCB with solder wave process only)" 
         "5.) HF logo (for PCB with Halogen-Free materials)" 
         "6.) \"BREADBOARD ONLY\" marking (for PCB release as breadboards only)"))
    ("DRC-3" "DRC-17" "Pin1 indicator must be visible. Do adjustments if necessary." comment nil nil)
    ("DRC-3" "DRC-18" "For boards with FUSE components, add fuse rating marking near to it." comment nil nil)
    ("DRC-3" "DRC-19" "Double check PTH components refdes. Must be readable and easy to recognize." comment nil nil)
    ("DRC-3" "DRC-20" "Check SMT components refdes orientation and location.\nUse textblock \"41\"" comment nil nil)
    ("DRC-3" "DRC-21" "Update Drill table and Slot table before proceeding to documentation." comment nil nil
	        (("NCDrill" "nctape_full") 
			("Generate Slot Table" "slot")))

    ("Doc" "DOC-1" "Double check copper thickness value of stackup details on PCB Specification page2." comment nil nil)
    ("Doc" "DOC-2" "Via with POFV process must be indicated on \"VIA FEATURE\" on Drill Chart of PCB Specification page3 (hole specs)." command "ncdrill legend" nil)
    ("Doc" "DOC-3" "Board dimension on PCB Specification page2 must be 2 decimal only." comment nil nil)
    ("Doc" "DOC-4" "Double check note location on PCB Specification page2." comment nil nil)
    ("Doc" "DOC-5" "Double check listed items below for 509 and 709 titleblocks:" comment nil nil 
        ("1.) Copyright Year" 
         "2.) \"in\" and \"held\" Confidential statement" 
         "3.) TLA number, Board PN, and Board name." 
         "4.) PCB Material, Finish board thickness, number of layers, and PCB Treatment." 
         "5.) Additional notes." 
         "6.) Uniform dates on all documents."))
    ("Doc" "DOC-6" "Delete \"Approved by\" and Approver name of specific area on the figure for both PCB Specification and PCB Assembly" comment nil nil)

    ("Digital" "DIG-1" "All impedance-controlled traces must have reference plane on its adjacent layer." comment nil "DIGITAL")
    ("Digital" "DIG-2" "Verify with DE the Impedance requirement for differential pairs." comment nil "DIGITAL")

    ("Meta" "CR-1" "Verify with DE if Canada RU US safety marking is required (cRUus)." comment nil "META")
    ("Meta" "CRA-1" "META projects must use 3 plies for Prepreg and Core." comment nil "META")
    ("Meta" "CRA-2" "META must use Halogen Free PCB laminates/materials." comment nil "META")

    ("Panasonic" "CRB-1" "Panasonic Model must use DOG BONE." comment nil "PANASONIC")
    ("Panasonic" "CRB-2" "PANASONIC boards - PCB CTI >= 175 or above." comment nil "PANASONIC")
    ("Panasonic" "CRB-3" "Must NOT HAVE silkscreen use as pad separation." comment nil "PANASONIC")
    ("Panasonic" "CRC-1" "RP48-70 AWS PANASONIC must NOT use Halogen-Free." comment nil "PANASONIC")
    ("Panasonic" "CRC-2" "HV800 AWS PANASONIC must NOT use Halogen-Free." comment nil "PANASONIC")
    ("Panasonic" "CRC-3" "HV800 model to use CTI >=600." comment nil "PANASONIC")
    ("Panasonic" "CRC-4" "PANASONIC AWS PCB must NOT order from Shengyi." comment nil "PANASONIC")

    ("Gerber" "FF-1" "Double check page sequence of PCB Spec." comment nil nil)
    ("Gerber" "FF-2" "Alignment of soldermask and component pads TOP/BOT." comment nil nil)
    ("Gerber" "FF-3" "Alignment of solderpaste and component pads TOP/BOT." comment nil nil)
    ("Gerber" "FF-4" "Alignment of drill hole and via/pth ALL layer." comment nil nil)
    ("Gerber" "FF-5" "Alignment of drill hole and drill symbol." comment nil nil)
	("Gerber" "FF-6" "For PCB with Daughter board PCBA that has 1.4mm/1.6mm pitch silver finger, please add .rou on gerber files. This is to include the slot of the finger pad." comment nil nil)
))

;; Popup text per item ID
unless(boundp('pcb_popup_text)
  pcb_popup_text = makeTable("pcb_popup_text" "")
)

;; ---- CUSTOM DESCRIPTION DICTIONARY ----
pcb_popup_text["R-8"] = "(DVT reminder)\n\nCheck:\n- All macros should be official (no temp macro)."
pcb_popup_text["DRC-1"] = "Best Practice. \n\nThis is to avoid artwork films modification for final release when generating Valor and MVR files."
pcb_popup_text["DRC-2"] = "This is a critical alignment step for manufacturing and smt process."
pcb_popup_text["DRC-3"] = "Note:Refer to section 4.2.1 of QP 920-000253-0000"
pcb_popup_text["DRC-4"] = "Update symbols version based on Valor Report. All macro should be on latest version."
pcb_popup_text["DRC-5"] = "Preferred distance must be >/= board thickness. \nRefer to section 4.11.17 of QP 920-000253-0000"
pcb_popup_text["DRC-6"] = "Always verify with ME if details were incomplete. \nVerify what type of screw will be using at what process. \n\nScrew should have PN."
pcb_popup_text["DRC-7"] = "These objects might not be visible on board level but could be check on assembly level. \n (e.g. standoff collar, connector screw, chassis, connector metal casing). \n \n \nAsk ME to provide 3D of whole project assembly."
pcb_popup_text["DRC-8"] = "Refer to section 3.1 of QP 920-000259-0000. \nAtleast 2 guide holes must be provided to individual PCB for precise indexing \n \non the test fixture for In-Circuit test (ICT). \n \n \n(3 guide holes must be provided if 0.7mm diameter testpad has been used.)"
pcb_popup_text["DRC-11"] = "Best practice. Add to visibility tab Soldermask for easy access."
pcb_popup_text["DRC-12"] = "Best practice. Open solderpaste_TOP/BOTTOM and cross check with vias."
pcb_popup_text["DRC-13"] = "And fix all crooked lines, aim the shortest path possible and less curve/turn."
pcb_popup_text["DRC-16"] = "Dead metals will always treat same as the circuit that is closest to it. \nDouble check the circuit creepage and apply it to dead metals that are in between different circuits."
pcb_popup_text["DRC-18"] = "Must be easy to recognize. Must not overlap with vias and holes to avoid being disfigured.\nMust not overlap with soldermask_opening."
pcb_popup_text["DRC-19"] = "Refer to Module3 part2 of Safety Module."
pcb_popup_text["DRC-20"] = "Must not overlap with vias and holes to avoid being disfigured. \nMust not overlap with soldermask_opening to avoid peel off."
pcb_popup_text["DOC-1"] = "Refer to QP 970-011346-0000 for correct value. \nNote: Always use thin copper for outer layer in PCB stack-up. \n \nRefer to section 9.2.6 of QP 920-000246-0000"
pcb_popup_text["DIG-1"] = "This is critical for ensuring proper circuit functionality and minimizing issues like noise, crosstalk, and signal integrity problems."

(setq pcb_categories '("Report" "DRC-1" "DRC-2" "DRC-3" "Doc" "Digital" "Meta" "Panasonic" "Gerber"))

;; Global state tables
unless(boundp('pcb_model_val) pcb_model_val = "")
unless(boundp('pcb_pn_val) pcb_pn_val = "")
unless(boundp('pcb_rev_val) pcb_rev_val = "")
unless(boundp('pcb_desc_val) pcb_desc_val = "")
unless(boundp('pcb_assy_val) pcb_assy_val = "")
unless(boundp('pcb_thick_val) pcb_thick_val = "")
unless(boundp('pcb_stage_val) pcb_stage_val = "Proto")

unless(boundp('pcb_skip_state) pcb_skip_state = makeTable("skip_state" nil))
unless(boundp('pcb_chk_state) pcb_chk_state = makeTable("checklist_state" nil))
unless(boundp('pcb_subchk_state) pcb_subchk_state = makeTable("subchk_state" nil))
unless(boundp('pcb_chk_comments) pcb_chk_comments = makeTable("checklist_comments" ""))
unless(boundp('pcb_subchk_comments) pcb_subchk_comments = makeTable("subchk_comments" ""))
unless(boundp('pcb_chk_logs) pcb_chk_logs = makeTable("checklist_logs" ""))
unless(boundp('pcb_sub_cmds) pcb_sub_cmds = makeTable("sub_cmds" ""))
unless(boundp('pcb_chk_warn) pcb_chk_warn = makeTable("checklist_warn" nil))

(setq pcb_active_cats nil)
foreach(cat pcb_categories if(cat != "Gerber" then pcb_active_cats = cons(cat pcb_active_cats)))
(setq pcb_active_cats reverse(pcb_active_cats))

(setq pcb_active_items nil)
foreach(item pcb_chk_data if(nth(0 item) != "Gerber" then pcb_active_items = cons(item pcb_active_items)))
(setq pcb_active_items reverse(pcb_active_items))

unless(boundp('pcb_last_form_loc) pcb_last_form_loc = nil)
unless(boundp('pcb_last_active_tab) pcb_last_active_tab = nil)

procedure( update_log_dir()
    let((base_name safe_pn safe_rev)
        safe_pn = buildString(parseString(pcb_pn_val "/\\:*?\"<>|") "-")
        safe_rev = buildString(parseString(pcb_rev_val "/\\:*?\"<>|") "-")
        
        if(safe_pn && safe_pn != "" then
            base_name = safe_pn
            if(safe_rev && safe_rev != "" then base_name = strcat(base_name "_" safe_rev))
            base_name = strcat(base_name "_Checklist")
        else
            base_name = "Checklist_Logs"
        )
        pcb_log_dir = strcat(axlOSSlash(getWorkingDir()) "/" base_name)
    )
)

procedure( save_pcb_state()
    let((fp save_file master_fp master_file)
        master_file = strcat(axlOSSlash(getWorkingDir()) "/pcb_checklist_last_session.il")
        master_fp = outfile(master_file "w")
        if(master_fp then
            fprintf(master_fp "pcb_model_val = %L\n" pcb_model_val)
            fprintf(master_fp "pcb_pn_val = %L\n" pcb_pn_val)
            fprintf(master_fp "pcb_rev_val = %L\n" pcb_rev_val)
            fprintf(master_fp "pcb_desc_val = %L\n" pcb_desc_val)
            fprintf(master_fp "pcb_assy_val = %L\n" pcb_assy_val)
            fprintf(master_fp "pcb_thick_val = %L\n" pcb_thick_val)
            close(master_fp)
        )

        update_log_dir()
        unless(isDir(pcb_log_dir) createDir(pcb_log_dir))
        save_file = strcat(pcb_log_dir "/pcb_checklist_save.il")
        fp = outfile(save_file "w")
        if(fp then
            fprintf(fp "pcb_model_val = %L\n" pcb_model_val)
            fprintf(fp "pcb_pn_val = %L\n" pcb_pn_val)
            fprintf(fp "pcb_rev_val = %L\n" pcb_rev_val)
            fprintf(fp "pcb_desc_val = %L\n" pcb_desc_val)
            fprintf(fp "pcb_assy_val = %L\n" pcb_assy_val)
            fprintf(fp "pcb_thick_val = %L\n" pcb_thick_val)
            fprintf(fp "pcb_stage_val = %L\n" pcb_stage_val)
            fprintf(fp "let((data)\n")
            fprintf(fp "data = '%L\n" tableToList(pcb_skip_state))
            fprintf(fp "foreach(item data pcb_skip_state[car(item)] = cadr(item))\n")
            fprintf(fp "data = '%L\n" tableToList(pcb_chk_state))
            fprintf(fp "foreach(item data pcb_chk_state[car(item)] = cadr(item))\n")
            fprintf(fp "data = '%L\n" tableToList(pcb_subchk_state))
            fprintf(fp "foreach(item data pcb_subchk_state[car(item)] = cadr(item))\n")
            fprintf(fp "data = '%L\n" tableToList(pcb_chk_comments))
            fprintf(fp "foreach(item data pcb_chk_comments[car(item)] = cadr(item))\n")
            fprintf(fp "data = '%L\n" tableToList(pcb_subchk_comments))
            fprintf(fp "foreach(item data pcb_subchk_comments[car(item)] = cadr(item))\n")			
			fprintf(fp "data = '%L\n" tableToList(pcb_chk_warn))
			fprintf(fp "foreach(item data pcb_chk_warn[car(item)] = cadr(item))\n")
            fprintf(fp ")\n")
            close(fp)
        )
    )
)

procedure( load_pcb_state()
    let((save_file)
        save_file = strcat(pcb_log_dir "/pcb_checklist_save.il")
        if(isFile(save_file) then errset(load(save_file) t))
    )
)

procedure( launch_pcb_checklist()
    let((master_file)
        master_file = strcat(axlOSSlash(getWorkingDir()) "/pcb_checklist_last_session.il")
        if(isFile(master_file) then errset(load(master_file) t))
    )
	pcb_load_report_scripts()
    
	if(!pcb_model_val || pcb_model_val == "" then pcb_model_val = pcb_fetch_var("Model"))
    if(!pcb_pn_val || pcb_pn_val == "" then pcb_pn_val = pcb_fetch_var("PartNumber"))
    if(!pcb_rev_val || pcb_rev_val == "" || pcb_rev_val == "2" then 
        let((v) v = pcb_fetch_var("Rev") if(v != "" then pcb_rev_val = v))
    )
    if(!pcb_desc_val || pcb_desc_val == "" then pcb_desc_val = pcb_fetch_var("Title"))
    if(!pcb_assy_val || pcb_assy_val == "" then pcb_assy_val = pcb_fetch_var("AssyDrawingNumber"))
    if(!pcb_thick_val || pcb_thick_val == "" then pcb_thick_val = pcb_fetch_var("boardthickness"))

    update_log_dir()
    load_pcb_state()
    run_pcb_checklist()
)

procedure( pcb_toggle_category_lock(frm cat is_locked)
    foreach(item pcb_active_items
        if(nth(0 item) == cat then
            let((id safe_id sub_idx)
                id = nth(1 item)
                safe_id = buildString(parseString(id "-") "_")
                
                if(cat == "Report" then
                    errset(axlFormSetFieldEditable(frm strcat("run_" safe_id) !is_locked) t)
                    errset(axlFormSetFieldEditable(frm strcat("cmt_" safe_id) !is_locked) t)
                    errset(axlFormSetFieldEditable(frm strcat("chk_" safe_id) !is_locked) t)
                else
                    errset(axlFormSetFieldEditable(frm strcat("chkY_" safe_id) !is_locked) t)
                    errset(axlFormSetFieldEditable(frm strcat("chkN_" safe_id) !is_locked) t)
                )
                
                if(length(item) > 6 then
                    sub_idx = 1
                    foreach(sub_item nth(6 item)
                        let((safe_sub_id sub_desc)
                            if(listp(sub_item) then sub_desc = nth(0 sub_item) else sub_desc = sub_item)
                            safe_sub_id = sprintf(nil "%d" sub_idx)
                            
                            if(cat == "Report" then
                                errset(axlFormSetFieldEditable(frm strcat("runsub_" safe_id "_" safe_sub_id) !is_locked) t)
                                errset(axlFormSetFieldEditable(frm strcat("cmtsub_" safe_id "_" safe_sub_id) !is_locked) t)
                                errset(axlFormSetFieldEditable(frm strcat("subchk_" safe_id "_" safe_sub_id) !is_locked) t)
                            else
                                if(rexMatchp("BREADBOARD" upperCase(sub_desc)) && pcb_stage_val != "Proto" then
                                    errset(axlFormSetFieldEditable(frm strcat("subY_" safe_id "_" safe_sub_id) nil) t)
                                    errset(axlFormSetFieldEditable(frm strcat("subN_" safe_id "_" safe_sub_id) nil) t)
                                else
                                    errset(axlFormSetFieldEditable(frm strcat("subY_" safe_id "_" safe_sub_id) !is_locked) t)
                                    errset(axlFormSetFieldEditable(frm strcat("subN_" safe_id "_" safe_sub_id) !is_locked) t)
                                )
                            )
                            sub_idx = sub_idx + 1
                        )
                    )
                )
            )
        )
    )
)

procedure( is_item_done_or_skipped(itm)
    let((id cat is_skipped)
        cat = nth(0 itm)
        id = nth(1 itm)
        is_skipped = nil
        if(cat == "Digital" && pcb_skip_state["DIGITAL"] then is_skipped = t)
        if(cat == "Meta" && pcb_skip_state["META"] then is_skipped = t)
        if(cat == "Panasonic" && pcb_skip_state["PANASONIC"] then is_skipped = t)
        if(is_skipped || pcb_chk_state[id] then t else nil)
    )
)

procedure( is_item_unlocked(target_id)
    let((unlocked idx prev_item)
        unlocked = t
        idx = -1
        for(i 0 length(pcb_active_items)-1
            if(nth(1 nth(i pcb_active_items)) == target_id then idx = i)
        )
        if(idx > 0 then
            prev_item = nth(idx-1 pcb_active_items)
            if(!is_item_done_or_skipped(prev_item) then unlocked = nil)
        )
        unlocked
    )
)

procedure( is_category_done(cat_name)
    let((cat_done itm_id is_skipped)
        if(cat_name == "Digital" && pcb_skip_state["DIGITAL"] then is_skipped = t)
        if(cat_name == "Meta" && pcb_skip_state["META"] then is_skipped = t)
        if(cat_name == "Panasonic" && pcb_skip_state["PANASONIC"] then is_skipped = t)
        
        if(is_skipped then
            t
        else
            cat_done = t
            foreach(itm pcb_active_items
                if(nth(0 itm) == cat_name then
                    itm_id = nth(1 itm)
                    if(!pcb_chk_state[itm_id] then cat_done = nil)
                )
            )
            cat_done
        )
    )
)

;; --- MAIN GUI GENERATOR ---
procedure( run_pcb_checklist()
    prog((fp frm form_file temp_rel_y y_pos max_rel_y tabset_h footer_y form_height item id desc type safe_id sub_desc sub_cmd safe_sub_id field_name field_name_cmt target_tab cx_code cx_act1 cx_act2 cx_chk cx_img cx_txt cat short_desc short_sub)
        
        unless(isDir(pcb_log_dir) createDir(pcb_log_dir))
        
        ;; V26 GENERATION
        form_file = strcat(pcb_log_dir "/pcb_wizard_ui_v26.form")
        fp = outfile(form_file "w")

        max_rel_y = 2
        foreach(cat pcb_active_cats
            temp_rel_y = 2
            foreach(item pcb_active_items
                if(nth(0 item) == cat then
                    temp_rel_y = temp_rel_y + 2
                    if(length(item) > 6 then
                        foreach(sub_item nth(6 item)
                            temp_rel_y = temp_rel_y + 2
                        )
                    )
                )
            )
            if(temp_rel_y > max_rel_y then max_rel_y = temp_rel_y)
        )
        
        tabset_h = max_rel_y + 2
        
        ;; TABS SHIFTED HIGHER TO Y=10
        footer_y = 10 + tabset_h + 1   
        form_height = footer_y + 9      

        fprintf(fp "FILE_TYPE=FORM_DEFN VERSION=2\n")
        fprintf(fp "FORM\n")
        fprintf(fp "FIXED\n")
        
        ;; --- OVERALL WIDTH COMPRESSED TO PORT 96 ---
        fprintf(fp "PORT 96 %d\n" form_height)
        fprintf(fp "HEADER \"PCB Checklist Wizard\"\n")
        
        fprintf(fp "POPUP <stage_pop> \"Proto\" \"Proto\",\"EVT\" \"EVT\",\"DVT\" \"DVT\",\"Masspro\" \"Masspro\"\n")
        fprintf(fp "TILE\n")

        ;; --- HIGHLY COMPRESSED HEADER ---
        ;; Row 1
        fprintf(fp "TEXT \"Model:\"\nTLOC 1 1\nENDTEXT\n")
        fprintf(fp "FIELD ui_model\nFLOC 12 1\nSTRFILLIN 18 35\nENDFIELD\n")
        
        fprintf(fp "TEXT \"Description:\"\nTLOC 33 1\nENDTEXT\n")
        fprintf(fp "FIELD ui_desc\nFLOC 34 1\nSTRFILLIN 25 50\nENDFIELD\n")
        
        fprintf(fp "TEXT \"Stage:\"\nTLOC 70 1\nENDTEXT\n")
        fprintf(fp "FIELD ui_stage\nFLOC 75 1\nENUMSET 11\nPOP \"stage_pop\"\nENDFIELD\n")

        ;; Row 2
        fprintf(fp "TEXT \"PCB Part Number:\"\nTLOC 1 3\nENDTEXT\n")
        fprintf(fp "FIELD ui_partnum\nFLOC 12 3\nSTRFILLIN 18 15\nENDFIELD\n")
        
        fprintf(fp "TEXT \"Assy Drawing:\"\nTLOC 33 3\nENDTEXT\n")
        fprintf(fp "FIELD ui_assy\nFLOC 34 3\nSTRFILLIN 25 30\nENDFIELD\n")
        
        fprintf(fp "TEXT \"Thickness:\"\nTLOC 70 3\nENDTEXT\n")
        fprintf(fp "FIELD ui_thick\nFLOC 75 3\nSTRFILLIN 11 15\nENDFIELD\n")

        ;; Row 3
        fprintf(fp "TEXT \"Revision:\"\nTLOC 1 5\nENDTEXT\n")
        fprintf(fp "FIELD ui_rev\nFLOC 12 5\nSTRFILLIN 5 3\nENDFIELD\n")

        ;; Row 4 (Checkboxes pulled closer together & Update Button merged)
        fprintf(fp "TEXT \"Skip Categories:\"\nTLOC 1 7\nENDTEXT\n")
        fprintf(fp "FIELD skip_DIGITAL\nFLOC 16 7\nCHECKLIST \"Digital\"\nENDFIELD\n")
        fprintf(fp "FIELD skip_META\nFLOC 26 7\nCHECKLIST \"Meta\"\nENDFIELD\n")
        fprintf(fp "FIELD skip_PANASONIC\nFLOC 32 7\nCHECKLIST \"Panasonic\"\nENDFIELD\n")
        
        fprintf(fp "FIELD update_info_btn\nFLOC 75 7\nMENUBUTTON \"Update Info\" 14 1\nENDFIELD\n")

        ;; TABS 
        fprintf(fp "TABSET \"category_tabs\"\n")
        fprintf(fp "FLOC 1 10\n")
        fprintf(fp "FSIZE 94 %d\n" tabset_h)

        foreach(cat pcb_active_cats
            fprintf(fp "TAB \"%s\"\n" cat)
            
            if(cat == "Report" then
                cx_code = 2 cx_act1 = 10 cx_act2 = 18 cx_chk = 28 cx_img = 33 cx_txt = 38
                fprintf(fp "TEXT \"CODE\"\nTLOC %d 1\nENDTEXT\n" cx_code)
                fprintf(fp "TEXT \"RUN\"\nTLOC %d 1\nENDTEXT\n" cx_act1 + 1)
                fprintf(fp "TEXT \"COMMENT\"\nTLOC %d 1\nENDTEXT\n" cx_act2)
                fprintf(fp "TEXT \"DONE\"\nTLOC %d 1\nENDTEXT\n" cx_chk - 1)
                fprintf(fp "TEXT \"?\"\nTLOC %d 1\nENDTEXT\n" cx_img + 1)
                fprintf(fp "TEXT \"DESCRIPTION\"\nTLOC %d 1\nENDTEXT\n" cx_txt)
            else
                cx_code = 2 cx_act1 = 12 cx_act2 = 18 cx_img = 24 cx_txt = 29
                fprintf(fp "TEXT \"CODE\"\nTLOC %d 1\nENDTEXT\n" cx_code)
                fprintf(fp "TEXT \"YES\"\nTLOC %d 1\nENDTEXT\n" cx_act1 - 1)
                fprintf(fp "TEXT \"NO\"\nTLOC %d 1\nENDTEXT\n" cx_act2 - 1)
                fprintf(fp "TEXT \"?\"\nTLOC %d 1\nENDTEXT\n" cx_img + 1)
                fprintf(fp "TEXT \"DESCRIPTION\"\nTLOC %d 1\nENDTEXT\n" cx_txt)
            )

            y_pos = 3
            foreach(item pcb_active_items
                if(nth(0 item) == cat then
                    id = nth(1 item)
                    desc = nth(2 item)
                    type = nth(3 item)
                    safe_id = buildString(parseString(id "-") "_")
                    
                    if(cat == "Report" then
                        short_desc = pcb_truncate_desc(desc 120)
                    else
                        short_desc = pcb_truncate_desc(desc 125)
                    )
                    
                    fprintf(fp "TEXT \"%s\"\nTLOC %d %d\nENDTEXT\n" id cx_code y_pos)
                    
                    if(cat == "Report" then
                        if(type == 'command then fprintf(fp "FIELD run_%s\nFLOC %d %d\nMENUBUTTON \"Run\" 6 1\nENDFIELD\n" safe_id cx_act1 y_pos))
                        fprintf(fp "FIELD cmt_%s\nFLOC %d %d\nMENUBUTTON \"Comment\" 8 1\nENDFIELD\n" safe_id cx_act2 y_pos)
                        fprintf(fp "FIELD chk_%s\nFLOC %d %d\nCHECKLIST \"\"\nENDFIELD\n" safe_id cx_chk y_pos)
                        fprintf(fp "FIELD img_%s\nFLOC %d %d\nMENUBUTTON \"?\" 3 1\nENDFIELD\n" safe_id cx_img y_pos)
                    else
                        fprintf(fp "FIELD chkY_%s\nFLOC %d %d\nCHECKLIST \"\"\nENDFIELD\n" safe_id cx_act1 y_pos)
                        fprintf(fp "FIELD chkN_%s\nFLOC %d %d\nCHECKLIST \"\"\nENDFIELD\n" safe_id cx_act2 y_pos)
                        fprintf(fp "FIELD img_%s\nFLOC %d %d\nMENUBUTTON \"?\" 3 1\nENDFIELD\n" safe_id cx_img y_pos)
                    )
                     
                    fprintf(fp "TEXT \"%s\"\nTLOC %d %d\nENDTEXT\n" short_desc cx_txt y_pos)
                    
                    y_pos = y_pos + 2
                    
                    if(length(item) > 6 then
                        sub_idx = 1
                        foreach(sub_item nth(6 item)
                            let((sub_cmd)
                                if(listp(sub_item) then sub_desc = nth(0 sub_item) else sub_desc = sub_item)
                                sub_cmd = if(listp(sub_item) then nth(1 sub_item) else nil)
                                safe_sub_id = sprintf(nil "%d" sub_idx)
                                
                                if(cat == "Report" then
                                    short_sub = pcb_truncate_desc(sub_desc 120)
                                else
                                    short_sub = pcb_truncate_desc(sub_desc 125)
                                )
                                
                                if(cat == "Report" then
                                    if(sub_cmd then
                                        field_name = strcat("runsub_" safe_id "_" safe_sub_id)
                                        fprintf(fp "FIELD %s\nFLOC %d %d\nMENUBUTTON \"Run\" 6 1\nENDFIELD\n" field_name cx_act1 y_pos)
                                        pcb_sub_cmds[field_name] = sub_cmd
                                    )
                                    field_name_cmt = strcat("cmtsub_" safe_id "_" safe_sub_id)
                                    fprintf(fp "FIELD %s\nFLOC %d %d\nMENUBUTTON \"Comment\" 8 1\nENDFIELD\n" field_name_cmt cx_act2 y_pos)
                                    field_name_chk = strcat("subchk_" safe_id "_" safe_sub_id)
                                    fprintf(fp "FIELD %s\nFLOC %d %d\nCHECKLIST \"\"\nENDFIELD\n" field_name_chk cx_chk y_pos)
                                else
                                    field_name_Y = strcat("subY_" safe_id "_" safe_sub_id)
                                    field_name_N = strcat("subN_" safe_id "_" safe_sub_id)
                                    fprintf(fp "FIELD %s\nFLOC %d %d\nCHECKLIST \"\"\nENDFIELD\n" field_name_Y cx_act1 y_pos)
                                    fprintf(fp "FIELD %s\nFLOC %d %d\nCHECKLIST \"\"\nENDFIELD\n" field_name_N cx_act2 y_pos)
                                    if(sub_cmd then pcb_sub_cmds[field_name_Y] = sub_cmd)
                                )
                                
                                fprintf(fp "TEXT \"%s\"\nTLOC %d %d\nENDTEXT\n" short_sub cx_txt y_pos)
                                
                                y_pos = y_pos + 2
                                sub_idx = sub_idx + 1
                            )
                        )
                    )
                )
            )
            fprintf(fp "TEXT \".\"\nTLOC 90 %d\nENDTEXT\n" y_pos)
            fprintf(fp "ENDTAB\n")
        )
        fprintf(fp "ENDTABSET\n")
        
        ;; === COMPACT FOOTER DASHBOARD ===
        fprintf(fp "FIELD ref_btn\nFLOC 2 %d\nMENUBUTTON \"Reference Docs\" 15 1\nENDFIELD\n" footer_y + 1)
        fprintf(fp "FIELD reset_btn\nFLOC 19 %d\nMENUBUTTON \"Reset List\" 12 1\nENDFIELD\n" footer_y + 1)
        
        fprintf(fp "FIELD export_btn\nFLOC 2 %d\nMENUBUTTON \"Export\" 15 1\nENDFIELD\n" footer_y + 3)
        fprintf(fp "FIELD close_btn\nFLOC 19 %d\nMENUBUTTON \"Close\" 12 1\nENDFIELD\n" footer_y + 3)

        fprintf(fp "TEXT \"Item Details & Image Launcher:\"\nTLOC 32 %d\nENDTEXT\n" footer_y)
        fprintf(fp "FIELD ui_details_list\nFLOC 32 %d\nLIST \"\" 62 6\nENDFIELD\n" footer_y + 1)
        
        fprintf(fp "ENDTILE\n")
        fprintf(fp "ENDFORM\n") 
        close(fp)
        
        frm = axlFormCreate(gensym() form_file '(e outer) 'pcb_chk_callback t)
        pcb_master_form = frm 
        
        if(!frm then axlUIConfirm("CRITICAL ERROR: Failed to create Cadence form.") return(nil))
        
        if(frm then
            when(fboundp('axlFormSetLoc) && pcb_last_form_loc
                axlFormSetLoc(frm pcb_last_form_loc)
            )
            
            errset(axlFormListDeleteItem(frm "ui_details_list" 'all) t)
            for(i 0 100 errset(axlFormListDeleteItem(frm "ui_details_list" 0) t))
            
            let((idx)
                idx = 0
                errset(axlFormListAddItem(frm "ui_details_list" "--- DETAILS PANEL ---" idx) t)
                idx = idx + 1
                errset(axlFormListAddItem(frm "ui_details_list" "Click the [ ? ] button next to any item to load the full description." idx) t)
            )
            
            axlFormSetField(frm "ui_model" pcb_model_val)
            axlFormSetField(frm "ui_partnum" pcb_pn_val)
            axlFormSetField(frm "ui_rev" pcb_rev_val)
            axlFormSetField(frm "ui_desc" pcb_desc_val)
            axlFormSetField(frm "ui_assy" pcb_assy_val)
            axlFormSetField(frm "ui_thick" pcb_thick_val)
            axlFormSetField(frm "ui_stage" pcb_stage_val)

            if(pcb_skip_state["DIGITAL"] then axlFormSetField(frm "skip_DIGITAL" t))
            if(pcb_skip_state["META"] then axlFormSetField(frm "skip_META" t))
            if(pcb_skip_state["PANASONIC"] then axlFormSetField(frm "skip_PANASONIC" t))
            
            if(boundp('pcb_last_active_tab) && pcb_last_active_tab && member(pcb_last_active_tab pcb_active_cats) then
                target_tab = pcb_last_active_tab
            else
                target_tab = nil
                foreach(cat pcb_active_cats
                    if(!target_tab && !is_category_done(cat) then target_tab = cat)
                )
                if(!target_tab then target_tab = nth(0 pcb_active_cats)) 
            )
            axlFormSetField(frm "category_tabs" target_tab)
            
            foreach(item pcb_active_items
                let((id safe_id sub_desc field_name cat state_key)
                    cat = nth(0 item)
                    id = nth(1 item)
                    safe_id = buildString(parseString(id "-") "_")
                    
                    if(cat == "Report" then
                        if(pcb_chk_state[id] then axlFormSetField(frm strcat("chk_" safe_id) t))
                    else
                        if(pcb_chk_state[id] == "YES" then axlFormSetField(frm strcat("chkY_" safe_id) t))
                        if(pcb_chk_state[id] == "NO" then axlFormSetField(frm strcat("chkN_" safe_id) t))
                    )
                    
                    if(length(item) > 6 then
                        sub_idx = 1
                        foreach(sub_item nth(6 item)
                            if(listp(sub_item) then sub_desc = nth(0 sub_item) else sub_desc = sub_item)
                            safe_sub_id = sprintf(nil "%d" sub_idx)
                            
                            if(cat == "Report" then
                                field_name = strcat("subchk_" safe_id "_" safe_sub_id)
                                if(pcb_subchk_state[field_name] then axlFormSetField(frm field_name t))
                            else
                                state_key = strcat("subchk_" safe_id "_" safe_sub_id)
                                field_name_Y = strcat("subY_" safe_id "_" safe_sub_id)
                                field_name_N = strcat("subN_" safe_id "_" safe_sub_id)
                                
                                if(rexMatchp("BREADBOARD" upperCase(sub_desc)) && pcb_stage_val != "Proto" then
                                    pcb_subchk_state[state_key] = "NO"
                                    axlFormSetField(frm field_name_Y nil)
                                    axlFormSetField(frm field_name_N t)
                                    axlFormSetFieldEditable(frm field_name_Y nil)
                                    axlFormSetFieldEditable(frm field_name_N nil)
                                else
                                    if(pcb_subchk_state[state_key] == "YES" then axlFormSetField(frm field_name_Y t))
                                    if(pcb_subchk_state[state_key] == "NO" then axlFormSetField(frm field_name_N t))
                                )
                            )
                            sub_idx = sub_idx + 1
                        )
                    )
                )
            )
            
            if(pcb_skip_state["DIGITAL"] then pcb_toggle_category_lock(frm "Digital" t))
            if(pcb_skip_state["META"] then pcb_toggle_category_lock(frm "Meta" t))
            if(pcb_skip_state["PANASONIC"] then pcb_toggle_category_lock(frm "Panasonic" t))
            
            axlFormDisplay(frm) 
            axlUIWPerm(frm t)
        )
    )
)

procedure( pcb_chk_callback(frm)
    prog((field val safe_id item id type cmd cat cmt_val sub_field all_done sub_desc file_prefix out_file out_port desc_clean work_dir root_dir cmd_str parts target_idx fail_cat current_board state_key sub_id cmt_key main_state)
        
        field = frm->curField
        val   = frm->curValue

        if(field == "update_info_btn" then
			pcb_model_val = pcb_fetch_var("Model")
            pcb_pn_val = pcb_fetch_var("PartNumber")
            let((v) v = pcb_fetch_var("Rev") if(v != "" then pcb_rev_val = v))
            pcb_desc_val = pcb_fetch_var("Title")
            pcb_assy_val = pcb_fetch_var("AssyDrawingNumber")
            pcb_thick_val = pcb_fetch_var("boardthickness")
            
			axlFormSetField(frm "ui_model" pcb_model_val)
            axlFormSetField(frm "ui_partnum" pcb_pn_val)
            axlFormSetField(frm "ui_rev" pcb_rev_val)
            axlFormSetField(frm "ui_desc" pcb_desc_val)
            axlFormSetField(frm "ui_assy" pcb_assy_val)
            axlFormSetField(frm "ui_thick" pcb_thick_val)
            
            axlUIConfirm("Success: Header information updated directly from board properties!")
            save_pcb_state()
            return(nil)
        )

        if(field == "ui_model" then pcb_model_val = val return(nil))
        if(field == "ui_partnum" then pcb_pn_val = val return(nil))
        if(field == "ui_rev" then pcb_rev_val = val return(nil))
        if(field == "ui_desc" then pcb_desc_val = val return(nil))
        if(field == "ui_assy" then pcb_assy_val = val return(nil))
        if(field == "ui_thick" then pcb_thick_val = val return(nil))

        if(field == "ui_stage" then
            pcb_stage_val = val
            foreach(item pcb_active_items
                let((id safe_id sub_idx cat)
                    cat = nth(0 item)
                    id = nth(1 item)
                    safe_id = buildString(parseString(id "-") "_")
                    if(length(item) > 6 then
                        sub_idx = 1
                        foreach(sub_item nth(6 item)
                            let((sub_desc state_key field_name_Y field_name_N is_skipped)
                                if(listp(sub_item) then sub_desc = nth(0 sub_item) else sub_desc = sub_item)
                                if(rexMatchp("BREADBOARD" upperCase(sub_desc)) then
                                    state_key = strcat("subchk_" safe_id "_" sprintf(nil "%d" sub_idx))
                                    field_name_Y = strcat("subY_" safe_id "_" sprintf(nil "%d" sub_idx))
                                    field_name_N = strcat("subN_" safe_id "_" sprintf(nil "%d" sub_idx))
                                    
                                    is_skipped = nil
                                    if(cat == "Digital" && pcb_skip_state["DIGITAL"] then is_skipped = t)
                                    if(cat == "Meta" && pcb_skip_state["META"] then is_skipped = t)
                                    if(cat == "Panasonic" && pcb_skip_state["PANASONIC"] then is_skipped = t)
                                    
                                    if(pcb_stage_val != "Proto" then
                                        pcb_subchk_state[state_key] = "NO"
                                        axlFormSetField(frm field_name_Y nil)
                                        axlFormSetField(frm field_name_N t)
                                        axlFormSetFieldEditable(frm field_name_Y nil)
                                        axlFormSetFieldEditable(frm field_name_N nil)
                                    else
                                        if(!is_skipped then
                                            axlFormSetFieldEditable(frm field_name_Y t)
                                            axlFormSetFieldEditable(frm field_name_N t)
                                        )
                                    )
                                )
                            )
                            sub_idx = sub_idx + 1
                        )
                    )
                )
            )
            save_pcb_state()
            return(nil)
        )

        if(frm->doneState == 2 || frm->doneState == 3 then
            when(fboundp('axlFormGetLoc) pcb_last_form_loc = axlFormGetLoc(frm))
            pcb_last_active_tab = axlFormGetField(frm "category_tabs")
            update_log_dir()
            save_pcb_state()
            return(nil)
        )
        
        when(field == "ref_btn"
          shell("explorer \"C:\\Your\\Folder\\Path\\Goes\\Here\"")
          return(nil)
        )

        ;; === RIGHT-SIDE DETAILS LIST & FAST IMAGE VIEWER ===
        if(rexMatchp("^img_" field) then
            let((img_name img_dir img_file launch_cmd tip msg_lines sub_desc_raw idx)
                parts = parseString(field "_")
                if(length(parts) >= 3 then safe_id = strcat(nth(1 parts) "_" nth(2 parts)) else safe_id = "")
                foreach(itm pcb_active_items if(buildString(parseString(nth(1 itm) "-") "_") == safe_id then item = itm))
                
                if(item then
                    id = nth(1 item)
                    
                    tip = pcb_popup_text[id]
                    if(!tip || tip == "" then 
                        tip = nth(2 item)
                        if(length(item) > 6 then
                            tip = strcat(tip "\n\nSub-Items:")
                            foreach(sub_item nth(6 item)
                                sub_desc_raw = if(listp(sub_item) then nth(0 sub_item) else sub_item)
                                tip = strcat(tip "\n  - " sub_desc_raw)
                            )
                        )
                    )
                    
                    errset(axlFormListDeleteItem(frm "ui_details_list" 'all) t)
                    for(i 0 100 errset(axlFormListDeleteItem(frm "ui_details_list" 0) t))
                    
                    msg_lines = pcb_split_lines(sprintf(nil "[ %s ]\n%s" id tip) 62)
                    
                    idx = 0
                    foreach(line msg_lines
                        errset(axlFormListAddItem(frm "ui_details_list" line idx) t)
                        idx = idx + 1
                    )

                    img_name = strcat(id ".jpg")
                    img_dir = "C:\\pcbenv\\figures"
                    img_file = strcat(img_dir "\\" img_name)
                    
                    if(!isFile(img_file) then 
                        img_file = strcat(img_dir "\\" car(parseString(img_name ".")) ".png")
                    )
                    
                    if(isFile(img_file) then
                        errset(axlFormListAddItem(frm "ui_details_list" "\n[ Reference Image Opened ]" idx) t)
                        launch_cmd = sprintf(nil "explorer.exe \"%s\"" img_file)
                        ipcBeginProcess(launch_cmd)
                    else
                        errset(axlFormListAddItem(frm "ui_details_list" "\n[ No image found ]" idx) t)
                    )
                )
            )
            return(nil)
        )

        if(field == "reset_btn" then
            if(axlUIYesNo("Are you sure you want to RESET this checklist?\nAll checkboxes and comments will be erased permanently!") then
                
                pcb_model_val = ""
                pcb_skip_state = makeTable("skip_state" nil) 
                pcb_chk_state = makeTable("checklist_state" nil)
                pcb_subchk_state = makeTable("subchk_state" nil) 
                pcb_chk_comments = makeTable("checklist_comments" "")
                pcb_subchk_comments = makeTable("subchk_comments" "")
				pcb_chk_warn = makeTable("checklist_warn" nil)
                
                pcb_pn_val = pcb_fetch_var("PartNumber")
                let((v) v = pcb_fetch_var("Rev") if(v != "" then pcb_rev_val = v else pcb_rev_val = "2"))
                pcb_desc_val = pcb_fetch_var("Title")
                pcb_assy_val = pcb_fetch_var("AssyDrawingNumber")
                pcb_thick_val = pcb_fetch_var("boardthickness")
                pcb_stage_val = "Proto" 
                
                update_log_dir()
                if(boundp('pcb_log_dir) && isDir(pcb_log_dir) then
                    foreach(file_name getDirFiles(pcb_log_dir)
                        if(rexMatchp("\\.log$" file_name) || rexMatchp("\\.csv$" file_name) then deleteFile(strcat(pcb_log_dir "/" file_name)))
                    )
                )
                save_pcb_state() 
                axlFormClose(frm) 
                run_pcb_checklist()
            )
            return(nil)
        )

        if(field == "category_tabs" then
            
            errset(axlFormListDeleteItem(frm "ui_details_list" 'all) t)
            for(i 0 100 errset(axlFormListDeleteItem(frm "ui_details_list" 0) t))
            
            let((idx)
                idx = 0
                errset(axlFormListAddItem(frm "ui_details_list" "--- DETAILS PANEL ---" idx) t)
                idx = idx + 1
                errset(axlFormListAddItem(frm "ui_details_list" "Click the [ ? ] button next to any item to load the full description." idx) t)
            )

            target_idx = 0
            for(i 0 length(pcb_active_cats)-1 if(nth(i pcb_active_cats) == val then target_idx = i))
            fail_cat = nil
            for(i 0 target_idx-1
                let((cat_to_check)
                    cat_to_check = nth(i pcb_active_cats)
                    if(!fail_cat && !is_category_done(cat_to_check) then fail_cat = cat_to_check)
                )
            )
            if(fail_cat then
                axlUIConfirm(sprintf(nil "STRICT SEQUENCE BLOCKER: You must complete all items in the '%s' category before viewing the '%s' tab." fail_cat val))
                axlFormSetField(frm "category_tabs" fail_cat)
                pcb_last_active_tab = fail_cat
            else
                pcb_last_active_tab = val
            )
            save_pcb_state()
            return(nil)
        )
        
        if(rexMatchp("^skip_" field) then 
            let((cat_key cat_name)
                cat_key = substring(field 6)
                pcb_skip_state[cat_key] = val 
                
                if(cat_key == "DIGITAL" then cat_name = "Digital")
                if(cat_key == "META" then cat_name = "Meta")
                if(cat_key == "PANASONIC" then cat_name = "Panasonic")
                
                pcb_toggle_category_lock(frm cat_name val)
                save_pcb_state()
            )
            return(nil)
        )

        if(rexMatchp("^chkY_" field) || rexMatchp("^chkN_" field) || rexMatchp("^subY_" field) || rexMatchp("^subN_" field) || rexMatchp("^chk_" field) || rexMatchp("^run_" field) || rexMatchp("^cmt_" field) || rexMatchp("^cmtsub_" field) || rexMatchp("^subchk_" field) || rexMatchp("^runsub_" field) then
            parts = parseString(field "_")
            if(length(parts) >= 3 then safe_id = strcat(nth(1 parts) "_" nth(2 parts)) else safe_id = "")
            
            item = nil
            foreach(itm pcb_active_items if(buildString(parseString(nth(1 itm) "-") "_") == safe_id then item = itm))
            
            if(item then
                id = nth(1 item) type = nth(3 item) cmd = nth(4 item) cat = nth(0 item)
                
                if(rexMatchp("^chkY_" field) then
                    if(val then
                        if(!is_item_unlocked(id) then
                            axlUIConfirm("STRICT SEQUENCE BLOCKER: You must complete the previous checklist item before interacting with this one.")
                            axlFormSetField(frm field nil) 
                            return(nil)
                        )
                        if(length(item) > 6 then
                            all_done = t
                            sub_idx = 1
                            foreach(sub_item nth(6 item)
                                state_key = strcat("subchk_" safe_id "_" sprintf(nil "%d" sub_idx))
                                if(!pcb_subchk_state[state_key] then all_done = nil)
                                sub_idx = sub_idx + 1
                            )
                            if(!all_done then
                                axlUIConfirm("RULE VIOLATION: You must complete all sub-items first!")
                                axlFormSetField(frm field nil)
                                return(nil)
                            )
                        )
                        if(type == 'command && cmd then
                            unless(errset(axlShell(cmd) t)
                                axlUIConfirm(sprintf(nil "FAILED TO RUN: %s" cmd))
                                axlFormSetField(frm field nil)
                                return(nil)
                            )
                        )
                        axlFormSetField(frm strcat("chkN_" safe_id) nil)
                        pcb_chk_state[id] = "YES"
                    else
                        pcb_chk_state[id] = nil
                    )
                    save_pcb_state()
                    return(nil)
                )

                if(rexMatchp("^chkN_" field) then
                    if(val then
                        if(!is_item_unlocked(id) then
                            axlUIConfirm("STRICT SEQUENCE BLOCKER: You must complete the previous checklist item before interacting with this one.")
                            axlFormSetField(frm field nil) 
                            return(nil)
                        )
                        if(length(item) > 6 then
                            all_done = t
                            sub_idx = 1
                            foreach(sub_item nth(6 item)
                                state_key = strcat("subchk_" safe_id "_" sprintf(nil "%d" sub_idx))
                                if(!pcb_subchk_state[state_key] then all_done = nil)
                                sub_idx = sub_idx + 1
                            )
                            if(!all_done then
                                axlUIConfirm("RULE VIOLATION: You must complete all sub-items first!")
                                axlFormSetField(frm field nil)
                                return(nil)
                            )
                        )
                        cmt_val = axlUIPrompt(sprintf(nil "Comment mandatory for NO on %s:" id) pcb_chk_comments[id])
                        if(cmt_val && cmt_val != "" then
                            axlFormSetField(frm strcat("chkY_" safe_id) nil)
                            pcb_chk_state[id] = "NO"
                            pcb_chk_comments[id] = cmt_val
                        else
                            axlUIConfirm("A comment is mandatory when selecting 'No'.")
                            axlFormSetField(frm field nil)
                        )
                    else
                        pcb_chk_state[id] = nil
                    )
                    save_pcb_state()
                    return(nil)
                )

                if(rexMatchp("^subY_" field) then
                    sub_id = nth(3 parts)
                    state_key = strcat("subchk_" safe_id "_" sub_id)
                    if(!is_item_unlocked(id) then
                        axlUIConfirm("STRICT SEQUENCE BLOCKER: You must complete the previous checklist item before interacting with this one.")
                        axlFormSetField(frm field nil) 
                        return(nil)
                    )
                    if(val then
                        if(pcb_sub_cmds[field] then 
                            unless(errset(axlShell(pcb_sub_cmds[field]) t)
                                axlUIConfirm(sprintf(nil "FAILED TO RUN COMMAND"))
                                axlFormSetField(frm field nil)
                                return(nil)
                            )
                        )
                        axlFormSetField(frm strcat("subN_" safe_id "_" sub_id) nil)
                        pcb_subchk_state[state_key] = "YES"
                    else
                        pcb_subchk_state[state_key] = nil
                    )
                    save_pcb_state()
                    return(nil)
                )

                if(rexMatchp("^subN_" field) then
                    sub_id = nth(3 parts)
                    state_key = strcat("subchk_" safe_id "_" sub_id)
                    cmt_key = strcat("cmtsub_" safe_id "_" sub_id)
                    if(!is_item_unlocked(id) then
                        axlUIConfirm("STRICT SEQUENCE BLOCKER: You must complete the previous checklist item before interacting with this one.")
                        axlFormSetField(frm field nil) 
                        return(nil)
                    )
                    if(val then
                        cmt_val = axlUIPrompt("Comment mandatory for NO:" pcb_subchk_comments[cmt_key])
                        if(cmt_val && cmt_val != "" then
                            axlFormSetField(frm strcat("subY_" safe_id "_" sub_id) nil)
                            pcb_subchk_state[state_key] = "NO"
                            pcb_subchk_comments[cmt_key] = cmt_val
                        else
                            axlUIConfirm("A comment is mandatory when selecting 'No'.")
                            axlFormSetField(frm field nil)
                        )
                    else
                        pcb_subchk_state[state_key] = nil
                    )
                    save_pcb_state()
                    return(nil)
                )

                if(!is_item_unlocked(id) then
                    axlUIConfirm("STRICT SEQUENCE BLOCKER: You must complete the previous checklist item before interacting with this one.")
                    if(rexMatchp("^chk_" field) || rexMatchp("^subchk_" field) then axlFormSetField(frm field nil)) 
                    return(nil)
                )
                
                if(rexMatchp("^runsub_" field) then if(pcb_sub_cmds[field] then axlShell(pcb_sub_cmds[field])) return(nil))

                if(rexMatchp("^cmtsub_" field) then
                    cmt_val = axlUIPrompt("Enter comment for this sub-item:" pcb_subchk_comments[field])
                    if(cmt_val then pcb_subchk_comments[field] = cmt_val)
                    save_pcb_state() return(nil)
                )

                if(rexMatchp("^cmt_" field) then
                    cmt_val = axlUIPrompt(sprintf(nil "Comment for %s:" id) pcb_chk_comments[id])
                    if(!cmt_val then return(nil))
                    
                    if(type == 'command && (null(pcb_chk_logs[id]) || pcb_chk_logs[id] == "") then
                        axlUIConfirm("Please click RUN first before adding a comment to proceed.")
                        return(nil)
                    )
                    
                    let((errCnt)
                        errCnt = nil
                        when(id == "R-1"  && boundp('r1_pf_errors)       errCnt = r1_pf_errors)
						when(id == "R-2"  && boundp('r2_error_count)    errCnt = r2_error_count)
                        when(id == "R-3"  && boundp('r3_missing_nets)    errCnt = r3_missing_nets)
                        when(id == "R-4"  && boundp('r4_short_count)     errCnt = r4_short_count)
                        when(id == "R-5"  && boundp('r5_error_count)     errCnt = r5_error_count)
                        when(id == "R-6"  && boundp('r6_error_count)     errCnt = r6_error_count)
                        when(id == "R-8"  && boundp('r8_error_count)     errCnt = r8_error_count)
                        when(id == "R-9"  && boundp('r9_error_count)     errCnt = r9_error_count)
                        when(id == "R-10"  && boundp('r10_error_count)     errCnt = r10_error_count)
                        when(id == "R-11" && boundp('r11_error_count)    errCnt = r11_error_count)
                        
                        if(numberp(errCnt) && errCnt > 0 then
                            unless(axlUIYesNo(sprintf(nil "%s still has %d issue(s).\nProceed anyway with a comment?" id errCnt))
                                return(nil)
                            )
                        )
                    )
                    
                    if(cmt_val != "" then
                        pcb_chk_comments[id] = cmt_val
                        pcb_chk_state[id] = t
                        axlFormSetField(frm strcat("chk_" safe_id) t)
                    else
                        pcb_chk_comments[id] = ""
                        pcb_chk_state[id] = nil
                        axlFormSetField(frm strcat("chk_" safe_id) nil)
                    )
                    save_pcb_state() 
                    return(nil)
                )

                if(rexMatchp("^run_" field) then
					
when(id == "R-1"  r1_pf_errors = 9999 r1_pf_count = 0)
when(id == "R-2"  r2_error_count = 999 r2_eval_count = 0 r2_fallback_status = "")
when(id == "R-3"  r3_missing_nets = 999)
when(id == "R-4"  r4_short_count = 999)
when(id == "R-5"  r5_error_count = 999)
when(id == "R-6"  r6_error_count = 999 r6_dummy_net_count = 0 r6_purged_nets = 0)
when(id == "R-8"  r8_error_count = 999)
when(id == "R-9"  r9_error_count = 999)
when(id == "R-10" r10_error_count = 999)
when(id == "R-11" r11_error_count = 999)

                    
                    when(cmd && type == 'command
                      unless(errset(axlShell(cmd) t)
                        axlUIConfirm(sprintf(nil "FAILED TO RUN: %s\n\nCheck that the logger .il is loaded and axlCmdRegister() exists for this command." cmd))
                        return(nil)
                      )
                    )
                    pcb_chk_logs[id] = getCurrentTime()

                    when(id == "R-1"
                      unless(boundp('r1_pf_errors) r1_pf_errors = 0)
                      unless(boundp('r1_pf_count)  r1_pf_count  = 0)
                      if(numberp(r1_pf_errors) && r1_pf_errors == 0 then
                        progn( pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else axlUIConfirm(sprintf(nil "R-1 Press-Fit Edge violations found: %d" r1_pf_errors)))
                    )
					
					

when(id == "R-2"
  unless(boundp('r2_error_count) r2_error_count = 999)
  if(numberp(r2_error_count) && r2_error_count == 0 then
    progn(
      pcb_chk_warn[id] = nil
      pcb_chk_state[id] = t
      axlFormSetField(frm strcat("chk_" safe_id) t)
    )
  else
    progn(
      pcb_chk_warn[id] = t
      axlUIConfirm(sprintf(nil "R-2 Hole-to-outline violations found: %d" r2_error_count))
    )
  )
)



                    when(id == "R-3"
                      unless(boundp('r3_missing_nets) r3_missing_nets = 999)
                      if(numberp(r3_missing_nets) && r3_missing_nets == 0 then
                        progn( pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else axlUIConfirm(sprintf(nil "R-3 Nets missing properties: %d" r3_missing_nets)))
                    )

                    when(id == "R-4"
                      unless(boundp('r4_short_count) r4_short_count = 999)
                      if(numberp(r4_short_count) && r4_short_count == 0 then
                        progn( pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else axlUIConfirm(sprintf(nil "R-4 Objects with NET_SHORT property found: %d" r4_short_count)))
                    )

                    when(id == "R-5"
                      unless(boundp('r5_error_count) r5_error_count = 999)
                      if(numberp(r5_error_count) && r5_error_count == 0 then
                        progn( pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else axlUIConfirm(sprintf(nil "R-5 Single/No Pin nets found: %d" r5_error_count)))
                    )

                    when(id == "R-6"
                      unless(boundp('r6_error_count) r6_error_count = 999)
                      if(numberp(r6_error_count) && r6_error_count == 0 then
                        progn( pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else axlUIConfirm(sprintf(nil "R-6 Dummy pins found: %d" r6_error_count)))
                    )

                    when(id == "R-7"
                      axlUIConfirm("R-7 Netlist is a MANDATORY REVIEW item.\nPlease review the opened log and click Comment to proceed.")
                    )

                    when(id == "R-8"
                      unless(boundp('r8_error_count) r8_error_count = 999)
                      if(numberp(r8_error_count) && r8_error_count == 0 then
                        progn( pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else axlUIConfirm(sprintf(nil "R-8 Unconnected pin pairs found: %d" r8_error_count)))
                    )

                    when(id == "R-9"
                      unless(boundp('r9_error_count) r9_error_count = 999)
                      if(numberp(r9_error_count) && r9_error_count == 0 then
                        progn( pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else axlUIConfirm(sprintf(nil "R-9 Issues found (Unplaced / Temp Macro): %d" r9_error_count)))
                    )

                    when(id == "R-10"
                      unless(boundp('r10_error_count) r10_error_count = 999)
                      if(numberp(r10_error_count) && r10_error_count == 0 then
                        progn( pcb_chk_warn[id] = nil pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else pcb_chk_warn[id] = t axlUIConfirm(sprintf(nil "R-10 Unused Blind/Buried vias found: %d" r10_error_count)))
                    )

                    when(id == "R-11"
                      unless(boundp('r11_error_count) r11_error_count = 999)
                      if(numberp(r11_error_count) && r11_error_count == 0 then
                        progn( pcb_chk_warn[id] = nil pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t) )
                      else pcb_chk_warn[id] = t axlUIConfirm(sprintf(nil "R-11 Waived DRCs found: %d" r11_error_count)))
                    )

                    if(boundp('pcb_log_dir) && isDir(pcb_log_dir) then
                        let((root_dir all_files src dest)
                            root_dir = getWorkingDir()
                            all_files = rexMatchList("\\.log$" getDirFiles(root_dir))
                            foreach(log_name all_files
                                if(rexMatchp("^R-" log_name) || rexMatchp("^DRC-" log_name) || rexMatchp("^r" log_name) then
                                    src = strcat(root_dir "/" log_name) dest = strcat(pcb_log_dir "/" log_name)
                                    if(isFile(dest) then deleteFile(dest)) renameFile(src dest)
                                )
                            )
                        )
                    )
                )

                if(rexMatchp("^subchk_" field) then 
                    if(val then 
                        sub_idx = 1
                        foreach(sub_item nth(6 item)
                            let((sub_field_name cmt_field_name)
                                sub_field_name = strcat("subchk_" safe_id "_" sprintf(nil "%d" sub_idx))
                                if(sub_field_name == field then
                                    if(listp(sub_item) then sub_desc = nth(0 sub_item) else sub_desc = sub_item)
                                    if(rexMatchp("NCDrill" sub_desc) || rexMatchp("Generate Slot" sub_desc) then
                                        cmt_field_name = strcat("cmtsub_" safe_id "_" sprintf(nil "%d" sub_idx))
                                        if(!pcb_subchk_comments[cmt_field_name] || pcb_subchk_comments[cmt_field_name] == "" then
                                            axlUIConfirm("RULE VIOLATION: You must add a Comment to this specific step before it can be checked Done!")
                                            axlFormSetField(frm field nil) return(nil)
                                        )
                                    )
                                )
                                sub_idx = sub_idx + 1
                            )
                        )
                    )
                    pcb_subchk_state[field] = val all_done = t sub_idx = 1
                    foreach(sub_item nth(6 item)
                        sub_field = strcat("subchk_" safe_id "_" sprintf(nil "%d" sub_idx))
                        if(!pcb_subchk_state[sub_field] then all_done = nil)
                        sub_idx = sub_idx + 1
                    )
                    if(all_done then pcb_chk_state[id] = t axlFormSetField(frm strcat("chk_" safe_id) t)
                    else pcb_chk_state[id] = nil axlFormSetField(frm strcat("chk_" safe_id) nil))
                    save_pcb_state() return(nil)
                )

                if(rexMatchp("^chk_" field) then 
                    if(val then 
                        if(length(item) > 6 then
                            all_done = t sub_idx = 1
                            foreach(sub_item nth(6 item)
                                sub_field = strcat("subchk_" safe_id "_" sprintf(nil "%d" sub_idx))
                                if(!pcb_subchk_state[sub_field] then all_done = nil)
                                sub_idx = sub_idx + 1
                            )
                            if(!all_done then
                                axlUIConfirm("RULE VIOLATION: You must tick all sub-items before checking Done!")
                                axlFormSetField(frm field nil) return(nil)
                            )
                        else
                            if(type != 'command then
                                if(!pcb_chk_comments[id] || pcb_chk_comments[id] == "" then
                                    axlUIConfirm("RULE VIOLATION: You must add a Comment before this item can be checked Done!")
                                    axlFormSetField(frm field nil) return(nil)
                                )
                            )
                        )
                        pcb_chk_state[id] = t 
                    else pcb_chk_state[id] = nil )
                    save_pcb_state()
                )
            )
        )
               
        if(field == "export_btn" then
            all_done = t
            fail_cat = nil
            foreach(cat pcb_active_cats
                if(!is_category_done(cat) then 
                    all_done = nil
                    if(!fail_cat then fail_cat = cat)
                )
            )
            if(!all_done then
                axlUIConfirm(sprintf(nil "STRICT SEQUENCE BLOCKER: You must complete all items in the '%s' category before exporting the final workbook." fail_cat))
                return(nil)
            )
            
            unless(isDir(pcb_log_dir) createDir(pcb_log_dir))
            if(!pcb_pn_val || pcb_pn_val == "" then file_prefix = "Unknown" else file_prefix = pcb_pn_val)
            if(pcb_rev_val && pcb_rev_val != "" then file_prefix = strcat(file_prefix "_Rev" pcb_rev_val))
            
            out_file = strcat(pcb_log_dir "/" file_prefix "_checklist.csv")
            out_port = outfile(out_file "w")
            
            if(out_port then
                fprintf(out_port "Model:,\"%s\"\nPCB Part Number:,\"%s\"\nPCB Part Number Revision:,\"%s\"\nPCB Description:,\"%s\"\nPCB Assembly Drawing Number:,\"%s\"\nStage:,\"%s\"\nBoard thickness:,\"%s\"\n\nCode,Details,Main Comment,Sub-Item Comments,Status (Yes/No)\n" 
                        pcb_model_val pcb_pn_val pcb_rev_val pcb_desc_val pcb_assy_val pcb_stage_val pcb_thick_val)
                foreach(itm pcb_chk_data 
                    let((all_sub_cmts itm_id safe_itm_id sub_field desc_clean cmt_clean sub_cmt_clean cat is_skipped main_state state_key cmt_key sub_state)
                        cat = nth(0 itm)
                        is_skipped = nil
                        if(cat == "Digital" && pcb_skip_state["DIGITAL"] then is_skipped = t)
                        if(cat == "Meta" && pcb_skip_state["META"] then is_skipped = t)
                        if(cat == "Panasonic" && pcb_skip_state["PANASONIC"] then is_skipped = t)
                        
                        itm_id = nth(1 itm)
                        safe_itm_id = buildString(parseString(itm_id "-") "_")
                        desc_clean = buildString(parseString(nth(2 itm) "\n") " ")
                        desc_clean = buildString(parseString(desc_clean "\"") "'")
                        
                        if(is_skipped then fprintf(out_port "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" itm_id desc_clean "" "" "SKIPPED")
                        else
                            all_sub_cmts = ""
                            if(length(itm) > 6 then
                                sub_idx = 1
                                foreach(sub_item nth(6 itm)
                                    if(listp(sub_item) then sub_desc = nth(0 sub_item) else sub_desc = sub_item)
                                    
                                    if(cat == "Report" then
                                        sub_field = strcat("cmtsub_" safe_itm_id "_" sprintf(nil "%d" sub_idx))
                                        if(pcb_subchk_comments[sub_field] && pcb_subchk_comments[sub_field] != "" then
                                            sub_cmt_clean = buildString(parseString(pcb_subchk_comments[sub_field] "\"") "'")
                                            sub_cmt_clean = buildString(parseString(sub_cmt_clean "\n") " ")
                                            all_sub_cmts = strcat(all_sub_cmts "• " sub_desc ": " sub_cmt_clean "\n")
                                        )
                                    else
                                        state_key = strcat("subchk_" safe_itm_id "_" sprintf(nil "%d" sub_idx))
                                        cmt_key = strcat("cmtsub_" safe_itm_id "_" sprintf(nil "%d" sub_idx))
                                        
                                        sub_state = pcb_subchk_state[state_key]
                                        if(!sub_state then sub_state = "PENDING")
                                        
                                        sub_cmt_clean = ""
                                        if(pcb_subchk_comments[cmt_key] && pcb_subchk_comments[cmt_key] != "" then
                                            sub_cmt_clean = buildString(parseString(pcb_subchk_comments[cmt_key] "\"") "'")
                                            sub_cmt_clean = buildString(parseString(sub_cmt_clean "\n") " ")
                                            sub_cmt_clean = strcat(" (" sub_cmt_clean ")")
                                        )
                                        all_sub_cmts = strcat(all_sub_cmts "• " sub_desc ": " sub_state sub_cmt_clean "\n")
                                    )
                                    sub_idx = sub_idx + 1
                                )
                            )
                            cmt_clean = pcb_chk_comments[itm_id]
                            if(cmt_clean then 
                                cmt_clean = buildString(parseString(cmt_clean "\"") "'")
                                cmt_clean = buildString(parseString(cmt_clean "\n") " ")
                            else cmt_clean = "")
                            
                            if(cat == "Report" then
                                fprintf(out_port "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" itm_id desc_clean cmt_clean all_sub_cmts if(pcb_chk_state[itm_id] "YES" "NO"))
                            else
                                main_state = pcb_chk_state[itm_id]
                                if(!main_state then main_state = "PENDING")
                                fprintf(out_port "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" itm_id desc_clean cmt_clean all_sub_cmts main_state)
                            )
                        )
                    )
                )
                close(out_port) 
                
                let((vbs_file vbs_port)
                    root_dir = buildString(parseString(getWorkingDir() "/") "\\")
                    work_dir = buildString(parseString(pcb_log_dir "/") "\\")
                    vbs_file = strcat(pcb_log_dir "/excel_compiler.vbs")
                    vbs_port = outfile(vbs_file "w")
                    if(vbs_port then
                        fprintf(vbs_port "Dim objExcel, objWB, objSheet, fso, rootFolder, logFolder, file, ts, row\n")
                        fprintf(vbs_port "Set fso = CreateObject(\"Scripting.FileSystemObject\")\n")
                        fprintf(vbs_port "Set objExcel = CreateObject(\"Excel.Application\")\n")
                        fprintf(vbs_port "objExcel.Visible = False\n")
                        fprintf(vbs_port "objExcel.DisplayAlerts = False\n")
                        fprintf(vbs_port "Dim prefix, csvFile, xlsxFile\n")
                        fprintf(vbs_port "prefix = WScript.Arguments(0)\n")
                        fprintf(vbs_port "rootFolder = \"%s\"\n" root_dir)
                        fprintf(vbs_port "logFolder = \"%s\"\n" work_dir)
                        fprintf(vbs_port "On Error Resume Next\n")
                        fprintf(vbs_port "For Each file in fso.GetFolder(rootFolder).Files\n")
                        fprintf(vbs_port "    If LCase(fso.GetExtensionName(file.Name)) = \"log\" Then\n")
                        fprintf(vbs_port "        If Left(UCase(file.Name), 2) = \"R-\" Or Left(UCase(file.Name), 4) = \"DRC-\" Then\n")
                        fprintf(vbs_port "            If fso.FileExists(logFolder & Chr(92) & file.Name) Then fso.DeleteFile(logFolder & Chr(92) & file.Name)\n")
                        fprintf(vbs_port "            fso.MoveFile file.Path, logFolder & Chr(92)\n")
                        fprintf(vbs_port "        End If\n")
                        fprintf(vbs_port "    End If\n")
                        fprintf(vbs_port "Next\n")
                        fprintf(vbs_port "On Error GoTo 0\n")
                        fprintf(vbs_port "csvFile = logFolder & Chr(92) & prefix & \"_checklist.csv\"\n")
                        fprintf(vbs_port "xlsxFile = logFolder & Chr(92) & prefix & \"_Master_Checklist.xlsx\"\n")
                        fprintf(vbs_port "Set objWB = objExcel.Workbooks.Add()\n")
                        
                        fprintf(vbs_port "If fso.FileExists(csvFile) Then\n")
                        fprintf(vbs_port "    Dim wbCSV, mSheet, lastRow\n")
                        fprintf(vbs_port "    Set wbCSV = objExcel.Workbooks.Open(csvFile)\n")
                        fprintf(vbs_port "    wbCSV.Sheets(1).Copy objWB.Sheets(1)\n")
                        fprintf(vbs_port "    wbCSV.Close False\n")
                        fprintf(vbs_port "    Set mSheet = objWB.Sheets(1)\n")
                        fprintf(vbs_port "    mSheet.Name = \"Master Checklist\"\n")
                        
                        fprintf(vbs_port "    lastRow = mSheet.Cells(mSheet.Rows.Count, 1).End(-4162).Row\n")
                        fprintf(vbs_port "    mSheet.Columns(\"B:D\").WrapText = True\n")
                        fprintf(vbs_port "    mSheet.Columns(\"A\").ColumnWidth = 10\n")
                        fprintf(vbs_port "    mSheet.Columns(\"B\").ColumnWidth = 50\n")
                        fprintf(vbs_port "    mSheet.Columns(\"C\").ColumnWidth = 35\n")
                        fprintf(vbs_port "    mSheet.Columns(\"D\").ColumnWidth = 45\n")
                        fprintf(vbs_port "    mSheet.Columns(\"E\").ColumnWidth = 15\n")
                        fprintf(vbs_port "    If lastRow >= 9 Then\n")
                        fprintf(vbs_port "        mSheet.Range(mSheet.Cells(9, 1), mSheet.Cells(lastRow, 5)).Borders.LineStyle = 1\n") 
                        fprintf(vbs_port "        mSheet.Range(\"A9:E9\").Interior.Color = RGB(146, 208, 80)\n") 
                        fprintf(vbs_port "        mSheet.Range(\"A9:E9\").Font.Bold = True\n")
                        fprintf(vbs_port "        mSheet.Range(\"A9:E9\").VerticalAlignment = -4108\n") 
                        fprintf(vbs_port "        mSheet.Rows.AutoFit\n")
                        fprintf(vbs_port "    End If\n")
                        fprintf(vbs_port "End If\n")
                        
                        fprintf(vbs_port "Dim fbSheet\n")
                        fprintf(vbs_port "Set fbSheet = objWB.Sheets.Add(, objWB.Sheets(\"Master Checklist\"))\n")
                        fprintf(vbs_port "fbSheet.Name = \"Feedback & Proof\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 1).Value = \"Entry #\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 2).Value = \"Description\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 3).Value = \"SCH\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 4).Value = \"PCB\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 5).Value = \"Additional Details\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 6).Value = \"Source\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 7).Value = \"Before\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 8).Value = \"After\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 9).Value = \"Date of Entry\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 10).Value = \"Date of Change/done\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 11).Value = \"Updated by PCB engineer?\"\n")
                        fprintf(vbs_port "fbSheet.Cells(1, 12).Value = \"REMARKS\"\n")
                        fprintf(vbs_port "fbSheet.Range(\"A1:L1\").Font.Bold = True\n")
                        fprintf(vbs_port "fbSheet.Range(\"A1:L1\").Interior.Color = RGB(220, 230, 241)\n")
                        fprintf(vbs_port "fbSheet.Columns(\"A:L\").ColumnWidth = 20\n")
                        
                        fprintf(vbs_port "For Each file in fso.GetFolder(logFolder).Files\n")
                        fprintf(vbs_port "    If LCase(fso.GetExtensionName(file.Name)) = \"log\" And (Left(UCase(file.Name), 2) = \"R-\" Or Left(UCase(file.Name), 4) = \"DRC-\") Then\n")
                        fprintf(vbs_port "        Set objSheet = objWB.Sheets.Add()\n")
                        fprintf(vbs_port "        objSheet.Move , objWB.Sheets(objWB.Sheets.Count)\n")
                        fprintf(vbs_port "        objSheet.Name = Left(Replace(file.Name, \".log\", \"\"), 31)\n")
                        fprintf(vbs_port "        Set ts = fso.OpenTextFile(file.Path, 1)\n")
                        fprintf(vbs_port "        row = 1\n")
                        fprintf(vbs_port "        Do Until ts.AtEndOfStream\n")
                        fprintf(vbs_port "            objSheet.Cells(row, 1).Value = ts.ReadLine\n")
                        fprintf(vbs_port "            row = row + 1\n")
                        fprintf(vbs_port "        Loop\n")
                        fprintf(vbs_port "        ts.Close\n")
                        fprintf(vbs_port "    End If\n")
                        fprintf(vbs_port "Next\n")
                        fprintf(vbs_port "On Error Resume Next\n")
                        fprintf(vbs_port "For Each objSheet In objWB.Sheets\n")
                        fprintf(vbs_port "    If Left(objSheet.Name, 5) = \"Sheet\" Then objSheet.Delete\n")
                        fprintf(vbs_port "Next\n")
                        fprintf(vbs_port "On Error GoTo 0\n")
                        fprintf(vbs_port "objWB.SaveAs xlsxFile, 51\n")
                        fprintf(vbs_port "objWB.Close False\n")
                        fprintf(vbs_port "objExcel.Quit\n")
                        fprintf(vbs_port "If fso.FileExists(csvFile) Then fso.DeleteFile(csvFile)\n")
                        close(vbs_port)
                        
                        cmd_str = sprintf(nil "cmd /c cscript //nologo \"%s\\excel_compiler.vbs\" \"%s\"" work_dir file_prefix)
                        shell(cmd_str)
                        shell(sprintf(nil "cmd /c del \"%s\\excel_compiler.vbs\"" work_dir))
                        axlUIConfirm("Export Complete! Check the folder for your Master Excel Workbook.")
                    )
                )
            )
        )
		when(field == "close_btn"
          when(fboundp('axlFormGetLoc) pcb_last_form_loc = axlFormGetLoc(frm))
          pcb_last_active_tab = axlFormGetField(frm "category_tabs")
          update_log_dir()
          save_pcb_state()
          axlFormClose(frm)
          return(nil)
        )
    )
)

