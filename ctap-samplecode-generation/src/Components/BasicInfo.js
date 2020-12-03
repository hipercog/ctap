import React, { useState, useEffect } from "react";
import TextField from '@material-ui/core/TextField';
import { makeStyles } from '@material-ui/core/styles';
import Autocomplete from '@material-ui/lab/Autocomplete';
import FormControlLabel from '@material-ui/core/FormControlLabel';
import Checkbox from '@material-ui/core/Checkbox';
import Container from '@material-ui/core/Container';
import { CTAP_chanlocs } from '../data/CTAP_chanlocs'

const useStyles = makeStyles((theme) => ({
    root: {
        '& .MuiTextField-root': {
            margin: theme.spacing(1),
            width: '35ch',
        },
    },
    words: {
        textAlign: "center",
    }

}));



const BasicInfo = ({ inputValue, setBasicInfoInput, basicInfoInputCheck, setBasicInfoInputCheck }) => {
    let classes = useStyles();
    const [value, setValue] = useState(inputValue.eegChanloc);

    useEffect(() => {
        setBasicInfoInput({ ...inputValue, eegChanloc: value });
        setBasicInfoInputCheck({...basicInfoInputCheck, eegChanloc:false});
    }, [value]);

    //handle input change
    const handleInput = event => {
        const { name, value } = event.target;
        setBasicInfoInput({ ...inputValue, [name]: value });
        setBasicInfoInputCheck({...basicInfoInputCheck, [name]:false});
    };

    const handleChange = (event) => {
        if (event.target.name === 'checkedLinear') {
            setBasicInfoInput({ ...inputValue, 'checkedLinear': event.target.checked, 'checkedBranch': !event.target.checked });
        } else if (event.target.name === 'checkedBranch') {
            setBasicInfoInput({ ...inputValue, 'checkedBranch': event.target.checked, 'checkedLinear': !event.target.checked });
        } else {
            setBasicInfoInput({ ...inputValue, [event.target.name]: event.target.checked });
        }
    };

    const handleHydraChange = (e) => {
        console.log(e.target.name)
        if (e.target.name === 'checkTimeRange') {
            let p = {};
            p = {...p, HydraOptionA: e.target.checked, HydraOptionB: !e.target.checked};
            if (e.target.checked) {
                console.log(e.target.checked);
                p = {...p, 'checkHydraCleanSeed': ''};
                setBasicInfoInputCheck({...basicInfoInputCheck, 'checkHydraCleanSeed':false})
            }
            setBasicInfoInput({ ...inputValue, ...p});
        } else {
            let p = {};
            p = {...p, HydraOptionB: e.target.checked, HydraOptionA:!e.target.checked};
            //setBasicInfoInput({ ...inputValue, HydraOptionB: e.target.checked, HydraOptionA:!e.target.checked });
            if (e.target.checked) {
                console.log(inputValue)
                p = {...p, 'checkHydraTimeRange': ''}
                setBasicInfoInputCheck({...basicInfoInputCheck, 'checkHydraTimeRange':false})
            }
            setBasicInfoInput({ ...inputValue, ...p});

        }
    }

    // console.log(basicInfoInputCheck)
    // console.log(inputValue)
    return (
        <form className={classes.root} noValidate autoComplete="off">
            <Container maxWidth="sm">
                <h4 >What type of pipeline* you would like to generate?</h4>
                <FormControlLabel
                    control={<Checkbox checked={inputValue.checkedLinear} onChange={handleChange} name="checkedLinear" />}
                    label="Linear Pipeline"
                />
                <FormControlLabel
                    control={<Checkbox checked={inputValue.checkedBranch} onChange={handleChange} name="checkedBranch" />}
                    label="Branch Pipeline"
                />
                <h5 className={classes.words}>* linear pipeline using different setpSets to group CTAP functions, the processing sequence depends on setpSets order. Branch pipeline generates sub-functions including predefined executable CTAP functions, which provides a more clear and flexible modular way to group functions. </h5>
                <div>
                    <FormControlLabel
                        control={<Checkbox checked={inputValue.checkedHYDRA} onChange={handleChange} name="checkedHYDRA" />}
                        label="Implementing HYDRA for artifacts parameter optimization or not?"
                    />
                    {inputValue.checkedHYDRA ? <div>
                        <div>
                            <FormControlLabel
                                control={<Checkbox checked={inputValue.HydraOptionA} onChange={handleHydraChange} name="checkTimeRange" />}
                                label="Provide clean data time-range"
                            />
                            <FormControlLabel
                                control={<Checkbox checked={inputValue.HydraOptionB} onChange={handleHydraChange} name="checkCleanSeed" />}
                                label="Provide clean seed data"
                            />
                            {inputValue.HydraOptionA ?
                                <div>
                                    <TextField
                                        error={basicInfoInputCheck.checkHydraTimeRange}
                                        id="checkHydraTimeRange"
                                        name="checkHydraTimeRange"
                                        label="Time Range"
                                        value={inputValue.checkHydraTimeRange}
                                        onChange={e => handleInput(e)}
                                        type="text"
                                        helperText={basicInfoInputCheck.checkHydraTimeRange ? 'The field cannot be empty. Please enter a value':"Set clean segment time range [start end] in seconds from test data"}
                                        variant="outlined"
                                    />
                                </div> : null}

                            {inputValue.HydraOptionB ?
                                <div>
                                    <TextField
                                        error={basicInfoInputCheck.checkHydraCleanSeed}
                                        id="checkHydraTimeRange"
                                        name="checkHydraCleanSeed"
                                        label="Seed Data Name"
                                        value={inputValue.checkHydraCleanSeed}
                                        onChange={e => handleInput(e)}
                                        type="text"
                                        helperText={basicInfoInputCheck.checkHydraCleanSeed ? 'The field cannot be empty. Please enter a value':"Name of the clean seed data file extract from test data"}
                                        variant="outlined"
                                    />

                                </div> : null}

                        </div>

                    </div> : null}
                    <hr></hr>

                </div>

            </Container>
            <div>
                <h4>Basic setting begin</h4>
                <TextField
                    error={basicInfoInputCheck.pipelineName}
                    id="pipelineName"
                    name="pipelineName"
                    label="Pipeline Name"
                    value={inputValue.pipelineName}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText={basicInfoInputCheck.pipelineName ? 'The field cannot be empty. Please enter a value':"Name a folder which contains outputs of pipes"}
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    error={basicInfoInputCheck.projectRoot}
                    id="projectRoot"
                    name="projectRoot"
                    label="Project Root"
                    value={inputValue.projectRoot}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText={basicInfoInputCheck.projectRoot ? 'The field cannot be empty. Please enter a value':"The root directory of the current analysis."}
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    error={basicInfoInputCheck.sbj_filt}
                    id="sbj_filt"
                    name="sbj_filt"
                    label="EEG File Name Sequence"
                    value={inputValue.sbj_filt}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText={basicInfoInputCheck.sbj_filt ? 'The field cannot be empty. Please enter a value':"The unique sequence number in EEG dataset name(sbj_filt)"}
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    error={basicInfoInputCheck.eegType}
                    id="eegType"
                    name="eegType"
                    label="EEG Data Type"
                    value={inputValue.eegType}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText={basicInfoInputCheck.eegType ? 'The field cannot be empty. Please enter a value':"EEG Data Type, eg, *.set/*.bdf"}
                    variant="outlined"
                />
            </div>
            <div>
                <Autocomplete
                    value={inputValue.eegChanloc}
                    onChange={(event, newValue) => {
                        setValue(newValue);
                    }}
                    id="controllable-states-demo"
                    options={CTAP_chanlocs}
                    renderInput={(params) => <TextField
                        {...params}
                        error={basicInfoInputCheck.eegChanloc}
                        helperText={basicInfoInputCheck.eegChanloc ? 'The field cannot be empty. Please enter a value':"Channel Location of testing EEG data "}
                        label="EEG Data Channel Location"
                        variant="outlined" />}
                />
            </div>
            <div>
                <TextField
                    error={basicInfoInputCheck.eegReference}
                    id="eegReference"
                    name="eegReference"
                    label="EEG Data Reference Channel"
                    value={inputValue.eegReference}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText={basicInfoInputCheck.eegReference ? 'The field cannot be empty. Please enter a value':"Reference channel of testing EEG data,  eg, {'L_MASTOID' 'R_MASTOID'}"}
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    error={basicInfoInputCheck.eegVeogChannelNames}
                    id="eegVeogChannelNames"
                    name="eegVeogChannelNames"
                    label="VEOG Channel Names"
                    value={inputValue.eegVeogChannelNames}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText={basicInfoInputCheck.eegVeogChannelNames ? 'The field cannot be empty. Please enter a value':"VEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'VEOG1','VEOG2'}"}
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    error={basicInfoInputCheck.eegHeogChannelNames}
                    id="eegHeogChannelNames"
                    name="eegHeogChannelNames"
                    label="HEOG Channel Names"
                    value={inputValue.eegHeogChannelNames}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText={basicInfoInputCheck.eegHeogChannelNames ? 'The field cannot be empty. Please enter a value':"HEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'HEOG1','HEOG2'}"}
                    variant="outlined"
                />
            </div>
        </form>
    )
};

export default BasicInfo;
