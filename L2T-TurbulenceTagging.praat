


# Include the auxiliary code files.
include ../Utilities/L2T-Utilities.praat
include ../StartupForm/L2T-StartupForm.praat
include ../Audio/L2T-Audio.praat
include ../WordList/L2T-WordList.praat
include ../SegmentationTextGrid/L2T-SegmentationTextGrid.praat
include ../TurbulenceLog/L2T-TurbulenceLog.praat
include ../TurbulenceTextGrid/L2T-TurbulenceTextGrid.praat



# Check whether all the objects that are necessary for turbulence tagging have
# been loaded to the Praat Objects list, and hence that the script is [ready]
# [.to_tag_turbulence_events].
procedure ready
  if (audio.praat_obj$ <> "") & 
     ... (wordlist.praat_obj$ <> "") &
     ... (segmentation_textgrid.praat_obj$ <> "") &
     ... (turbulence_log.praat_obj$ <> "") &
     ... (turbulence_textgrid.praat_obj$ <> "")
    .to_tag_turbulence_events = 1
  else
    .to_tag_turbulence_events = 0
  endif
endproc


# Information about the current trial being tagged.
procedure current_trial_to_tag
  # Determine the [.row_on_wordlist] that designates the current trial.
  select 'turbulence_log.praat_obj$'
  .row_on_wordlist = Get value... 1 'turbulence_log_columns.tagged_trials$'
  .row_on_wordlist = .row_on_wordlist + 1
  # Consult the WordList table to look-up the current trial's...
  select 'wordlist.praat_obj$'
  # ... Trial Number
  .trial_number$ = Get value... '.row_on_wordlist'
                           ... 'wordlist_columns.trial_number$'
  # ... Target Word
  .target_word$ = Get value... '.row_on_wordlist'
                           ... 'wordlist_columns.word$'
  # ... Target Consonant
  .target_c$ = Get value... '.row_on_wordlist'
                        ... 'wordlist_columns.target_c$'
  # ... Target Vowel
  .target_v$ = Get value... '.row_on_wordlist'
                        ... 'wordlist_columns.target_v$'
  # Determine the xmin, xmid, and xmax of the [interval] on the 'TrialNumber' 
  # tier of the segmented TextGrid that corresponds to the current trial.
  @interval: segmentation_textgrid.praat_obj$,
         ... segmentation_textgrid_tiers.trial,
         ... .trial_number$
  .xmin = interval.xmin
  .xmid = interval.xmid
  .xmax = interval.xmax
  .zoom_xmin = .xmin - 0.20
  .zoom_xmax = .xmax + 0.20
endproc


# Grab the responsive elicitations of a trial.
procedure responsive_elicitations
  # Extract the Trial from the Segmentation TextGrid, and export the name
  # of the new TextGrid.
  .textgrid$ = segmentation_textgrid.praat_obj$
  @extract_interval: .textgrid$,
                 ... current_trial_to_tag.xmin,
                 ... current_trial_to_tag.xmax
  .trial_textgrid$ = extract_interval.praat_obj$
  # Transform the extracted TextGrid down to a Table, and export the name 
  # of the new Table.
  @textgrid2table: .trial_textgrid$
  .trial_table$ = textgrid2table.praat_obj$
  # Subset the [.trial_table$] to just the rows on the Context tier.
  select '.trial_table$'
  Extract rows where column (text)... tier "is equal to" Context
  .elicitations_table$ = selected$()
  # Subset the [.elicitations_table$] to those elicitations that were
  # response, i.e. whose Context label is not 'NonResponse'
  select '.elicitations_table$'
  Extract rows where column (text)... text "is not equal to" NonResponse
  .responses_table$ = selected$()
  # Rename the [.responses_table$]
  @participant: turbulence_textgrid.write_to$,
            ... session_parameters.participant_number$
  .table_obj$ = participant.id$ + "_" +
            ... current_trial_to_tag.trial_number$ + "_" +
            ... "Responses"
  select '.responses_table$'
  Rename... '.table_obj$'
  .praat_obj$ = selected$()
  # Get the number of responsive elicitations.
  select '.praat_obj$'
  .n_responses = Get number of rows
  # Clean up all of the intermediary Praat Objects.
  @remove: .trial_textgrid$
  @remove: .trial_table$
  @remove: .elicitations_table$
endproc


# Information about the current response being tagged.
procedure current_response: .row_on_responses_table
  @boundary_times: responsive_elicitations.praat_obj$,
               ... .row_on_responses_table,
               ... segmentation_textgrid.praat_obj$,
               ... segmentation_textgrid_tiers.context
  # Import the times from the [@boundary_times] namespace.
  .xmin = boundary_times.xmin
  .xmid = boundary_times.xmid
  .xmax = boundary_times.xmax
  .duration = .xmax - .xmin
  # Set the limits of the zoom window.
  .zoom_xmin = .xmin - 0.25
  .zoom_xmax = .xmax + 0.25
endproc


# A procedure to highlight the current response in the Editor window
procedure highlight_current_response
  editor 'turbulence_textgrid.praat_obj$'
    Select: current_response.xmin, current_response.xmax
  endeditor  
endproc


# A vector-procedure for the [consonant_types]
procedure consonant_types
  .sib_fric$    = "Sibilant fricative"
  .sib_affr$    = "Sibilant affricate"
  .nonsib_fric$ = "Non-sibilant fricative"
  .nonsib_plos$ = "Non-sibilant plosive"
  .other$       = "Other"
  # Gather the Consonant Types into a vector.
  .slot1$ = .sib_fric$
  .slot2$ = .sib_affr$
  .slot3$ = .nonsib_fric$
  .slot4$ = .nonsib_plos$
  .slot5$ = .other$
  .length = 5
endproc

# Prompt the user to judge the consonant type of the response and add any
# supplementary notes.
procedure judge_response
  @consonant_types
  .pause_title$ = current_trial_to_tag.trial_number$ + " :: " +
              ... "Response " + "'row_on_responses_table'" + " out of " + 
              ... "'responsive_elicitations.n_responses'"
  beginPause: .pause_title$
    comment: "Please listen to the current production and tell me about it."
    comment: "Word: 'current_trial_to_tag.target_word$'"
    comment: "Consonant: 'current_trial_to_tag.target_c$'"
    comment: "Vowel: 'current_trial_to_tag.target_v$'"
    comment: "Start time: 'current_response.xmin'"
    comment: "End time: 'current_response.xmax'"
    comment: ""
    optionMenu: "Consonant type", 1
    for i to consonant_types.length
      option: consonant_types.slot'i'$
    endfor
    comment: "If the consonant is a sibilant fricative, please transcribe its Place."
      if current_trial_to_tag.target_c$ == "s"
        optionMenu: "Fricative place", 1
          option: "s"
          option: "s:$S"
          option: "$S:s"
          option: "$S"
          option: "other"
      
      elif current_trial_to_tag.target_c$ == "S"
        optionMenu: "Fricative place", 4
          option: "$s"
          option: "$s:S"
          option: "S:$s"
          option: "S"
          option: "other"
      endif
    optionMenu: "Notes", 1
      option: ""
      option: "Malaprop"
      option: "OverlappingResponse"
      option: "BackgroundNoise"
    word: "If Malaprop", ""
    boolean: "Include a consOnset tag", 0
    boolean: "Include a turbOffset tag", 0
  endPause: "", "Tag it!", 2, 1
  # Export variables to [current_response] namespace.
  current_response.consonant_type$ = consonant_type$
  if consonant_type$ == consonant_types.sib_fric$
    current_response.consonant_label$ = "'consonant_type$';'fricative_place$'"
  else
    current_response.consonant_label$ = consonant_type$
  endif
  if notes$ == "Malaprop"
    notes$ = "Malaprop: 'malaprop$'"
  endif
  current_response.notes$ = notes$
  current_response.has_consOnset_tag = include_a_consOnset_tag
  current_response.has_turbOffset_tag = include_a_turbOffset_tag
endproc


# Insert boundaries, on the IntervalTiers of the Turbulence Tagging TextGrid,
# which mark the extent of the current response.
procedure insert_boundaries .tier
  select 'turbulence_textgrid.praat_obj$'
  Insert boundary... '.tier'
                 ... 'current_response.xmin'
  Insert boundary... '.tier'
                 ... 'current_response.xmax'
endproc


# Add to the TextGrid, the ConsType information for the current response.
procedure tag_consonant_type
  # Insert the interval boundaries.
  @insert_boundaries: turbulence_textgrid_tiers.cons_type
  # Determine the interval number on the ConsType tier.
  @interval_at_time: turbulence_textgrid.praat_obj$,
                 ... turbulence_textgrid_tiers.cons_type,
                 ... current_response.xmid
  # Label the interval.
  @label_interval: turbulence_textgrid.praat_obj$,
               ... turbulence_textgrid_tiers.cons_type,
               ... interval_at_time.interval,
               ... current_response.consonant_label$
endproc


procedure response_is_sibilant
  if (current_response.consonant_type$ == consonant_types.sib_fric$) |
     ... (current_response.consonant_type$ == consonant_types.sib_affr$)
    .then_tag_events = 1
  else
    .then_tag_events = 0
  endif
endproc

# Set the turbulence events labels and times for the current response.
procedure turbulence_events
  .cons_onset$  = "consOnset"
  .turb_onset$  = "turbOnset"
  .turb_offset$ = "turbOffset"
  .vot$         = "VOT"
  .vowel_end$   = "vowelEnd"
  # Gather the turbulence event tags into a vector that is specific to the
  # current response.
  if current_response.has_consOnset_tag
    .slot1$ = .cons_onset$
    .slot2$ = .turb_onset$
    if current_response.has_turbOffset_tag
      .slot3$ = .turb_offset$
      .slot4$ = .vot$
      .slot5$ = .vowel_end$
    else
      .slot3$ = .vot$
      .slot4$ = .vowel_end$
    endif
  else
    .slot1$ = .turb_onset$
    if current_response.has_turbOffset_tag
      .slot2$ = .turb_offset$
      .slot3$ = .vot$
      .slot4$ = .vowel_end$
    else
      .slot2$ = .vot$
      .slot3$ = .vowel_end$
    endif
  endif
  .length = 3 + current_response.has_consOnset_tag + 
        ... current_response.has_turbOffset_tag
  # Determine the times at which the turbulence event tags should be dropped.
  .time1 = current_response.xmin + (0.1 * current_response.duration)
  .time'.length' = current_response.xmax - (0.1 * current_response.duration)
  .increment = (.time'.length' - .time1) / (.length - 1)
  for i from 2 to (.length - 1)
    .time'i' = .time1 + (.increment * (i - 1))
  endfor
endproc


# Add to the TextGrid, the TurbEvents information for the current response.
procedure tag_turbulence_events
  @turbulence_events
  for i to turbulence_events.length
    @insert_point: turbulence_textgrid.praat_obj$,
               ... turbulence_textgrid_tiers.turb_events,
               ... turbulence_events.time'i',
               ... turbulence_events.slot'i'$
  endfor
endproc


# Add to the TextGrid, the TurbNotes information for the current response.
procedure tag_turbulence_notes
  if current_response.notes$ <> ""
    # Insert the interval boundaries.
    @insert_boundaries: turbulence_textgrid_tiers.turb_notes
    # Determine the interval number on the TurbNotes tier.
    @interval_at_time: turbulence_textgrid.praat_obj$,
                   ... turbulence_textgrid_tiers.turb_notes,
                   ... current_response.xmid
    # Label the interval.
    @label_interval: turbulence_textgrid.praat_obj$,
                 ... turbulence_textgrid_tiers.turb_notes,
                 ... interval_at_time.interval,
                 ... current_response.notes$
  endif
endproc



procedure tag_response
  # Always tag the ConsType.
  @tag_consonant_type
  # Check to see if the production is sibilant, i.e. whether there are any
  # turbulence events to tag.
  @response_is_sibilant
  if response_is_sibilant.then_tag_events
    @tag_turbulence_events
  endif
  # Always tag the TurbNotes.
  @tag_turbulence_notes
endproc


procedure save_progress
  select 'turbulence_log.praat_obj$'
  Save as tab-separated file... 'turbulence_log.write_to$'
  select 'turbulence_textgrid.praat_obj$'
  Save as text file... 'turbulence_textgrid.write_to$'
endproc


procedure clean_up_and_quit
  @remove: audio.praat_obj$
  @remove: wordlist.praat_obj$
  @remove: segmentation_textgrid.praat_obj$
  @remove: turbulence_log.praat_obj$
  @remove: turbulence_textgrid.praat_obj$
  continue_tagging = 0
endproc


procedure what_now
  .move_on$   = "Move on to the next response"
  .extract$   = "Extract the response that I just tagged"
  .save_quit$ = "Save my progress & quit"
  .in_between_trials = row_on_responses_table ==
                       ... responsive_elicitations.n_responses
  if .in_between_trials
    .pause_title$ = "Finished tagging " + current_trial_to_tag.trial_number$
  else
    .pause_title$ = "Currently tagging " + current_trial_to_tag.trial_number$
  endif
  beginPause: .pause_title$
    comment: "Please adjust all of the event-points on the TurbEvents Tier."
    comment: "Once you've finished that, let me know what you want to do next."
    choice: "I want to", 1
      option: .move_on$
      option: .extract$
      if .in_between_trials
        option: .save_quit$
      endif
  endPause: "", "Do it!", 2, 1
  .choice$ = i_want_to$
endproc


procedure congratulations_on_a_job_well_done
  beginPause: "Congratulations!"
    comment: "You've finished tagging!  Thank you for your hard work!"
    comment: "If you would like to tag another file, just re-run the script."
  endPause: "Don't click me", "Click me", 2, 1
endproc


procedure increment_trials_tagged
  select 'turbulence_log.praat_obj$'
  .n_segmented = Get value... 1 'turbulence_log_columns.tagged_trials$'
  .n_segmented = .n_segmented + 1
  Set numeric value... 1 'turbulence_log_columns.tagged_trials$' '.n_segmented'
endproc




################################################################################
#  Main procedure                                                              #
################################################################################

# Set the session parameters.
@session_parameters
#printline 'session_parameters.initials$'
#printline 'session_parameters.workstation$'
#printline 'session_parameters.experimental_task$'
#printline 'session_parameters.testwave$'
#printline 'session_parameters.participant_number$'
#printline 'session_parameters.activity$'
#printline 'session_parameters.analysis_directory$'
printline Data directory: 'session_parameters.experiment_directory$'

# Load the audio file
@audio

# Load the WordList.
@wordlist

# Load the checked segmented TextGrid.
@segmentation_textgrid

# Load the Turbulence Tagging Log.
@turbulence_log

# Load the Turbulence Tagging TextGrid.
@turbulence_textgrid

# Check if the Praat Objects list is [ready] to proceed 
# [.to_tag_turbulence_events].
@ready
if ready.to_tag_turbulence_events
  printline Ready to turbulence tag: 'turbulence_textgrid.praat_obj$'
  # Open an Editor window, displaying the Sound object and the 
  # Turbulence TextGrid.
  @open_editor: turbulence_textgrid.praat_obj$,
            ... audio.praat_obj$
  # Enter a while-loop, within which the tagging is performed.
  continue_tagging = 1
  while continue_tagging
    # Get information about the [current_trial_to_tag].
    @current_trial_to_tag
    # Determine whether the current trial has any [responsive_elicitations].
    @responsive_elicitations
    # If there are [responsive_elicitations], tag them.
    if responsive_elicitations.n_responses > 0
      for row_on_responses_table to responsive_elicitations.n_responses
        # Get the information about the current response.
        @current_response: row_on_responses_table
        # Zoom to the interval of the current response.
        @zoom: turbulence_textgrid.praat_obj$,
           ... current_response.zoom_xmin,
           ... current_response.zoom_xmax
        # Highlight the current production in the Editor window.
        @highlight_current_response
        # Display a Praat Form, with which the tagger can judge the current
        # response.
        @judge_response
        # Tag the current response, using the tagger's judgments.
        @tag_response
        # Save progress
        @save_progress
        # Prompt the user to determine what to do next.
        @what_now
        if what_now.choice$ == what_now.move_on$
          # Nothing else needs to be done.  The while- and for-loops will
          # take care of it.
        elif what_now.choice$ == what_now.extract$
          # Fill this in with Mary's "extract snippets" code.
        elif what_now.choice$ == what_now.save_quit$
          @increment_trials_tagged
          @save_progress
          @clean_up_and_quit
        endif
      endfor
    else
      # If there were no [responsive_elicitations], then mark this Trial as
      # having no responses.
    endif
    # Remove the table of [responsive_elicitations]
    @remove: responsive_elicitations.praat_obj$
    # After all of the [current_trial]'s responses have been tagged, check to
    # see if the [current_trial] is the last trial that needs to be tagged,
    # and if so, congratulate the tagger on a good job done, then quit it.
    if current_trial_to_tag.row_on_wordlist == wordlist.n_trials
      @save_progress
      @clean_up_and_quit
      @congratulations_on_a_job_well_done
    elif what_now.choice$ != what_now.save_quit$
      @increment_trials_tagged
    endif
  endwhile
endif




