import React, { useState, useEffect } from "react";
import TextField from '@material-ui/core/TextField';
import { makeStyles } from '@material-ui/core/styles';
import Autocomplete from '@material-ui/lab/Autocomplete';
import Accordion from '@material-ui/core/Accordion';
import AccordionSummary from '@material-ui/core/AccordionSummary';
import AccordionDetails from '@material-ui/core/AccordionDetails';
import FormControlLabel from '@material-ui/core/FormControlLabel';
import Checkbox from '@material-ui/core/Checkbox';
import Container from '@material-ui/core/Container';
import Tooltip from '@material-ui/core/Tooltip';
import Typography from "@material-ui/core/Typography";
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import MoreOutlinedIcon from '@material-ui/icons/MoreOutlined';

import { CTAP_chanlocs } from '../data/CTAP_chanlocs'
import CTAP_Linear_diagram from '../Styles/CTAP_Linear.png'
import CTAP_Branch_diagram from '../Styles/CTAP_Branch.png'

const useStyles = makeStyles((theme) => ({
    root: {
        '& .MuiTextField-root': {
            margin: theme.spacing(1),
            width: '35ch',
        },
    },
    words: {
        textAlign: "center",
    },
    customWidth: {
        maxWidth: 500,
    },
}));

const helperText = {
    checkHydraTimeRange: "Set clean segment time range [start end] in seconds from test data",
    checkHydraCleanSeed: "Name of the clean seed data file extract from test data",
    pipelineName: "Name a folder which contains outputs of pipes",
    projectRoot: "The root directory of the current analysis.",
    sbj_filt: "The unique sequence number in EEG dataset name(sbj_filt)",
    eegType: "EEG Data Type, eg, *.set/*.bdf",
    eegChanloc: "Channel Location of testing EEG data ",
    eegReference: "Reference channel of testing EEG data,  eg, {'L_MASTOID' 'R_MASTOID'}",
    eegVeogChannelNames: "VEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'VEOG1','VEOG2'}",
    eegHeogChannelNames: "HEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'HEOG1','HEOG2'}"
};

const BasicInfo = ({ inputValue, setBasicInfoInput, basicInfoInputCheck, setBasicInfoInputCheck }) => {
    let classes = useStyles();
    const [value, setValue] = useState(inputValue.eegChanloc);

    useEffect(() => {
        setBasicInfoInput({ ...inputValue, eegChanloc: value });
        setBasicInfoInputCheck({ ...basicInfoInputCheck, eegChanloc: false });
    }, [value]);

    //handle input change
    const handleInput = event => {
        const { name, value } = event.target;
        setBasicInfoInput({ ...inputValue, [name]: value });
        setBasicInfoInputCheck({ ...basicInfoInputCheck, [name]: false });
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
            p = { ...p, HydraOptionA: e.target.checked, HydraOptionB: !e.target.checked };
            if (e.target.checked) {
                console.log(e.target.checked);
                p = { ...p, 'checkHydraCleanSeed': '' };
                setBasicInfoInputCheck({ ...basicInfoInputCheck, 'checkHydraCleanSeed': false })
            }
            setBasicInfoInput({ ...inputValue, ...p });
        } else {
            let p = {};
            p = { ...p, HydraOptionB: e.target.checked, HydraOptionA: !e.target.checked };
            //setBasicInfoInput({ ...inputValue, HydraOptionB: e.target.checked, HydraOptionA:!e.target.checked });
            if (e.target.checked) {
                console.log(inputValue)
                p = { ...p, 'checkHydraTimeRange': '' }
                setBasicInfoInputCheck({ ...basicInfoInputCheck, 'checkHydraTimeRange': false })
            }
            setBasicInfoInput({ ...inputValue, ...p });

        }
    }

    // console.log(basicInfoInputCheck)
    // console.log(inputValue)
    return (
        <form className={classes.root} noValidate autoComplete="off">
            <Container maxWidth="md" style={{ marginTop: '3rem' }}>
                <h4 >What type of pipeline* you would like to generate?</h4>
                <Accordion style={{ width: 750, margin: '0 auto' }}>
                    <AccordionSummary
                        expandIcon={<MoreOutlinedIcon />}
                        aria-label="Expand"
                        aria-controls="additional-actions1-content"
                        id="additional-actions1-header"
                    >
                        <FormControlLabel
                            aria-label="Acknowledge"
                            onClick={(event) => event.stopPropagation()}
                            onFocus={(event) => event.stopPropagation()}
                            control={<Checkbox checked={inputValue.checkedLinear} onChange={handleChange} name="checkedLinear" />}
                            label="Linear Pipeline"
                        />
                    </AccordionSummary>
                    <AccordionDetails>
                        <img src={CTAP_Linear_diagram} width="700" />
                    </AccordionDetails>
                </Accordion>
                <Accordion style={{ width: 750, margin: '0 auto' }}>
                    <AccordionSummary
                        expandIcon={<MoreOutlinedIcon />}
                        aria-label="Expand"
                        aria-controls="additional-actions1-content"
                        id="additional-actions1-header"
                    >
                        <FormControlLabel
                            aria-label="Acknowledge"
                            onClick={(event) => event.stopPropagation()}
                            onFocus={(event) => event.stopPropagation()}
                            control={<Checkbox checked={inputValue.checkedBranch} onChange={handleChange} name="checkedBranch" />}
                            label="Branch Pipeline"
                        />
                    </AccordionSummary>
                    <AccordionDetails>
                        <img src={CTAP_Branch_diagram} width="700" />
                    </AccordionDetails>
                </Accordion>
                <h5 className={classes.words}>* Click Linear and Brach tabs to see diagrams describe these two different pipelines. </h5>

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
                                    <Tooltip title={<Typography variant='body2'>{helperText.checkHydraTimeRange}</Typography>} classes={{ tooltip: classes.customWidth }}>
                                        <TextField
                                            error={basicInfoInputCheck.checkHydraTimeRange}
                                            id="checkHydraTimeRange"
                                            name="checkHydraTimeRange"
                                            label="Time Range"
                                            value={inputValue.checkHydraTimeRange}
                                            onChange={e => handleInput(e)}
                                            type="text"
                                            helperText={basicInfoInputCheck.checkHydraTimeRange ? 'The field cannot be empty. Please enter a value' : null}
                                            variant="outlined"
                                        />
                                    </Tooltip>

                                </div> : null}

                            {inputValue.HydraOptionB ?
                                <div>
                                    <Tooltip title={<Typography variant='body2'>{helperText.checkHydraCleanSeed}</Typography>} classes={{ tooltip: classes.customWidth }}>
                                        <TextField
                                            error={basicInfoInputCheck.checkHydraCleanSeed}
                                            id="checkHydraCleanSeed"
                                            name="checkHydraCleanSeed"
                                            label="Seed Data Name"
                                            value={inputValue.checkHydraCleanSeed}
                                            onChange={e => handleInput(e)}
                                            type="text"
                                            helperText={basicInfoInputCheck.checkHydraCleanSeed ? 'The field cannot be empty. Please enter a value' : null}
                                            variant="outlined"
                                        />
                                    </Tooltip>


                                </div> : null}

                        </div>

                    </div> : null}
                    <hr></hr>

                </div>

            </Container>
            <div style={{ marginTop: '0.8rem' }}>
                <h4>Basic setting begin</h4>
                <Tooltip title={<Typography variant='body2'>{helperText.pipelineName}</Typography>} classes={{ tooltip: classes.customWidth }}>
                    <TextField
                        error={basicInfoInputCheck.pipelineName}
                        id="pipelineName"
                        name="pipelineName"
                        label="Pipeline Name"
                        value={inputValue.pipelineName}
                        onChange={e => handleInput(e)}
                        type="text"
                        helperText={basicInfoInputCheck.pipelineName ? 'The field cannot be empty. Please enter a value' : null}
                        variant="outlined"
                    />
                </Tooltip>

            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <Tooltip title={<Typography variant='body2'>{helperText.projectRoot}</Typography>} classes={{ tooltip: classes.customWidth }}>
                    <TextField
                        error={basicInfoInputCheck.projectRoot}
                        id="projectRoot"
                        name="projectRoot"
                        label="Project Root"
                        value={inputValue.projectRoot}
                        onChange={e => handleInput(e)}
                        type="text"
                        helperText={basicInfoInputCheck.projectRoot ? 'The field cannot be empty. Please enter a value' : null}
                        variant="outlined"
                    />
                </Tooltip>

            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <Tooltip title={<Typography variant='body2'>{helperText.sbj_filt}</Typography>} classes={{ tooltip: classes.customWidth }}>
                    <TextField
                        error={basicInfoInputCheck.sbj_filt}
                        id="sbj_filt"
                        name="sbj_filt"
                        label="EEG File Name Sequence"
                        value={inputValue.sbj_filt}
                        onChange={e => handleInput(e)}
                        type="text"
                        helperText={basicInfoInputCheck.sbj_filt ? 'The field cannot be empty. Please enter a value' : null}
                        variant="outlined"
                    />
                </Tooltip>

            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <Tooltip title={<Typography variant='body2'>{helperText.eegType}</Typography>} classes={{ tooltip: classes.customWidth }}>
                    <TextField
                        error={basicInfoInputCheck.eegType}
                        id="eegType"
                        name="eegType"
                        label="EEG Data Type"
                        value={inputValue.eegType}
                        onChange={e => handleInput(e)}
                        type="text"
                        helperText={basicInfoInputCheck.eegType ? 'The field cannot be empty. Please enter a value' : null}
                        variant="outlined"
                    />
                </Tooltip>

            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <Tooltip title={<Typography variant='body2'>{helperText.eegChanloc}</Typography>} classes={{ tooltip: classes.customWidth }}>
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
                            helperText={basicInfoInputCheck.eegChanloc ? 'The field cannot be empty. Please enter a value' : null}
                            label="EEG Data Channel Location"
                            variant="outlined" />}
                    />
                </Tooltip>
            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <Tooltip title={<Typography variant='body2'>{helperText.eegReference}</Typography>} classes={{ tooltip: classes.customWidth }}>
                    <TextField
                        error={basicInfoInputCheck.eegReference}
                        id="eegReference"
                        name="eegReference"
                        label="EEG Data Reference Channel"
                        value={inputValue.eegReference}
                        onChange={e => handleInput(e)}
                        type="text"
                        helperText={basicInfoInputCheck.eegReference ? 'The field cannot be empty. Please enter a value' : null}
                        variant="outlined"
                    />
                </Tooltip>
            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <Tooltip title={<Typography variant='body2'>{helperText.eegVeogChannelNames}</Typography>} classes={{ tooltip: classes.customWidth }}>
                    <TextField
                        error={basicInfoInputCheck.eegVeogChannelNames}
                        id="eegVeogChannelNames"
                        name="eegVeogChannelNames"
                        label="VEOG Channel Names"
                        value={inputValue.eegVeogChannelNames}
                        onChange={e => handleInput(e)}
                        type="text"
                        helperText={basicInfoInputCheck.eegVeogChannelNames ? 'The field cannot be empty. Please enter a value' : null}
                        variant="outlined"
                    />
                </Tooltip>
            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <Tooltip title={<Typography variant='body2'>{helperText.eegHeogChannelNames}</Typography>} classes={{ tooltip: classes.customWidth }}>
                    <TextField
                        error={basicInfoInputCheck.eegHeogChannelNames}
                        id="eegHeogChannelNames"
                        name="eegHeogChannelNames"
                        label="HEOG Channel Names"
                        value={inputValue.eegHeogChannelNames}
                        onChange={e => handleInput(e)}
                        type="text"
                        helperText={basicInfoInputCheck.eegHeogChannelNames ? 'The field cannot be empty. Please enter a value' : null}
                        variant="outlined"
                    />
                </Tooltip>
            </div>
        </form>
    )
};

export default BasicInfo;
