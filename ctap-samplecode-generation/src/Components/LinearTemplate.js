
const LinearTemplate = (basicInfo, inputFields) => {
    let ctap_args = [];
    let stepSetsArray = [];
    inputFields.map((inputField, index) => {
        let funcs = ``;
        inputField.funcsSettings.map(funcsSetting => {
            funcs = funcs + `@${funcsSetting.functionName}, `;
            ctap_args.push(`out.${funcsSetting.functionName}=struct(${funcsSetting.functionP})`)
        });
        stepSetsArray.push(`stepSet(${index+1}).id{${inputField.stepID}};`);
        stepSetsArray.push(`stepSet(${index+1}).funH{${funcs}};`);
    })
    console.log(stepSetsArray);
    console.log(ctap_args);


    return new Array(
        `pipeline_name = '${basicInfo.pipelineName}';`,
        "FILE_ROOT = mfilename('fullpath');",
        `reporoot = FILE_ROOT(1:strfind(FILE_ROOT, fullfile('ctap', 'templates', '${basicInfo.projectRoot}', 'ctap_linear_template')) - 1);`,
        `project_dir = FILE_ROOT(1:strfind(FILE_ROOT, fullfile('ctap_linear_template')) - 1);`,
        `data_dir = append(reporoot,'ctap/data/test_data');`,
        `Cfg.env.paths = cfg_create_paths(project_dir, pipeline_name, {''}, 1);`,
        `Cfg.eeg.chanlocs = '${basicInfo.eegChanloc};'`,
        `Cfg.eeg.reference = ${basicInfo.eegReference};`,
        `Cfg.eeg.veogChannelNames = ${basicInfo.eegVeogChannelNames};`,
        `Cfg.eeg.heogChannelNames = ${basicInfo.eegHeogChannelNames};`,
        `Cfg.grfx.on = false;`,
        `Cfg.MC = get_meas_cfg_MC(Cfg, data_dir, 'eeg_ext', '${basicInfo.eegType}', 'sbj_filt', ${basicInfo.sbj_filt});`,
        `clear Pipe;`,
        `${stepSetsArray.join('\n')}`,
        `${ctap_args.join('\n')}`,
        `Cfg.pipe.stepSets = stepSet;`,
        `Cfg.pipe.runSets = {stepSet(1).id};`,
        `Cfg = ctap_auto_config(Cfg, out);`,
        `%% Run the pipe`,
        `CTAP_pipeline_looper(Cfg, 'debug', DEBUG, 'overwrite', true);`,
        `clear i stepSet Filt ctap_args`

    )

};

export default LinearTemplate;

// linearStepInfo