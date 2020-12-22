import React, { useState, useEffect, useContext } from "react";
import clsx from 'clsx';
import FormControl from '@material-ui/core/FormControl';
import TextField from '@material-ui/core/TextField';
import { makeStyles } from '@material-ui/core/styles';
import Autocomplete, { createFilterOptions } from '@material-ui/lab/Autocomplete';
import Accordion from '@material-ui/core/Accordion';
import AccordionSummary from '@material-ui/core/AccordionSummary';
import AccordionDetails from '@material-ui/core/AccordionDetails';
import FormControlLabel from '@material-ui/core/FormControlLabel';
import Checkbox from '@material-ui/core/Checkbox';
import Container from '@material-ui/core/Container';
import Tooltip from '@material-ui/core/Tooltip';
import Typography from "@material-ui/core/Typography";
import MoreOutlinedIcon from '@material-ui/icons/MoreOutlined';

import { ContextBasic } from '../Reducers/ContextProvider'

import { CTAP_chanlocs } from '../data/CTAP_chanlocs'
import CTAP_Linear_diagram from '../Styles/CTAP_Linear.png'
import CTAP_Branch_diagram from '../Styles/CTAP_Branch.png'

const filter = createFilterOptions();
const useStyles = makeStyles((theme) => ({
    margin: {
        margin: theme.spacing(1),
    },
    withoutLabel: {
        marginTop: theme.spacing(1),
    },
    textField: {
        width: '25ch',
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
    inputdatapath: 'Input path of test data',
    projectRoot: "The root directory of the current analysis.",
    sbj_filt: "The unique sequence number in EEG dataset name(sbj_filt)",
    eegType: "EEG Data Type, eg, *.set/*.bdf",
    eegChanloc: "Channel Location of testing EEG data ",
    eegReference: "Reference channel of testing EEG data,  eg, {'L_MASTOID' 'R_MASTOID'}",
    eegVeogChannelNames: "VEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'VEOG1','VEOG2'}",
    eegHeogChannelNames: "HEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'HEOG1','HEOG2'}"
};

const BasicInfo = ({ basicInfoInputCheck, setBasicInfoInputCheck }) => {
    let classes = useStyles();

    const [basicInfoInput, dispatch] = useContext(ContextBasic);
    const [value, setValue] = useState(basicInfoInput.eegChanloc);

    useEffect(() => {
        dispatch({ type: 'UPDATE', data: { ...basicInfoInput, eegChanloc: value } });
        setBasicInfoInputCheck({ ...basicInfoInputCheck, eegChanloc: false });
    }, [value]);

    //handle input change
    const handleInput = event => {
        const { name, value } = event.target;
        dispatch({ type: 'UPDATE', data: { ...basicInfoInput, [name]: value } });
        setBasicInfoInputCheck({ ...basicInfoInputCheck, [name]: false });
    };

    //handle checkbox change
    const handleCheckboxChange = (event) => {
        const { name, checked } = event.target;
        if (name === 'checkedLinear') {
            dispatch({ type: 'UPDATE', data: { ...basicInfoInput, 'checkedLinear': checked, 'checkedBranch': !checked } });
        } else if (name === 'checkedBranch') {
            dispatch({ type: 'UPDATE', data: { ...basicInfoInput, 'checkedBranch': checked, 'checkedLinear': !checked } });
        } else if (name === 'checkOwnDataPath') {
            dispatch({ type: 'UPDATE', data: { ...basicInfoInput, [name]: checked } });
            // initialize data path if disable own path option
            if (!checked) {
                setBasicInfoInputCheck({ ...basicInfoInputCheck, inputdatapath: false });
                dispatch({ type: 'UPDATE', data: { ...basicInfoInput, [name]: checked, inputdatapath: "ctap/data/test_data" } });
            }
        }
        else {
            dispatch({ type: 'UPDATE', data: { ...basicInfoInput, [name]: checked } });
        }
    };

    //handle hydra option
    const handleHydraChange = (e) => {
        if (e.target.name === 'checkTimeRange') {
            let p = {};
            p = { ...p, HydraOptionA: e.target.checked, HydraOptionB: !e.target.checked };
            if (e.target.checked) {
                console.log(e.target.checked);
                p = { ...p, 'checkHydraCleanSeed': '' };
                setBasicInfoInputCheck({ ...basicInfoInputCheck, 'checkHydraCleanSeed': false })
            }
            dispatch({ type: 'UPDATE', data: { ...basicInfoInput, ...p } });

        } else {
            let p = {};
            p = { ...p, HydraOptionB: e.target.checked, HydraOptionA: !e.target.checked };
            //setBasicInfoInput({ ...basicInfoInput, HydraOptionB: e.target.checked, HydraOptionA:!e.target.checked });
            if (e.target.checked) {
                p = { ...p, 'checkHydraTimeRange': '' }
                setBasicInfoInputCheck({ ...basicInfoInputCheck, 'checkHydraTimeRange': false })
            }
            dispatch({ type: 'UPDATE', data: { ...basicInfoInput, ...p } });
        }
    }

    // console.log(basicInfoInputCheck);
    // console.log(basicInfoInput)
    return (
        <div className={classes.root} noValidate autoComplete="off">
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
                            control={<Checkbox checked={basicInfoInput.checkedLinear} onChange={handleCheckboxChange} name="checkedLinear" />}
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
                            control={<Checkbox checked={basicInfoInput.checkedBranch} onChange={handleCheckboxChange} name="checkedBranch" />}
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
                        control={<Checkbox checked={basicInfoInput.checkedHYDRA} onChange={handleCheckboxChange} name="checkedHYDRA" />}
                        label="Implementing HYDRA for artifacts parameter optimization or not?"
                    />
                    {basicInfoInput.checkedHYDRA ? <div>
                        <div>
                            <FormControlLabel
                                control={<Checkbox checked={basicInfoInput.HydraOptionA} onChange={handleHydraChange} name="checkTimeRange" />}
                                label="Provide clean data time-range"
                            />
                            <FormControlLabel
                                control={<Checkbox checked={basicInfoInput.HydraOptionB} onChange={handleHydraChange} name="checkCleanSeed" />}
                                label="Provide clean seed data"
                            />
                            {basicInfoInput.HydraOptionA ?
                                <div>
                                    <Tooltip title={<Typography variant='body2'>{helperText.checkHydraTimeRange}</Typography>} classes={{ tooltip: classes.customWidth }}>
                                        <TextField
                                            error={basicInfoInputCheck.checkHydraTimeRange}
                                            id="checkHydraTimeRange"
                                            name="checkHydraTimeRange"
                                            label="Time Range"
                                            value={basicInfoInput.checkHydraTimeRange}
                                            onChange={e => handleInput(e)}
                                            type="text"
                                            helperText={basicInfoInputCheck.checkHydraTimeRange ? 'The field cannot be empty. Please enter a value' : null}
                                            variant="outlined"
                                        />
                                    </Tooltip>

                                </div> : null}

                            {basicInfoInput.HydraOptionB ?
                                <div>
                                    <Tooltip title={<Typography variant='body2'>{helperText.checkHydraCleanSeed}</Typography>} classes={{ tooltip: classes.customWidth }}>
                                        <TextField
                                            error={basicInfoInputCheck.checkHydraCleanSeed}
                                            id="checkHydraCleanSeed"
                                            name="checkHydraCleanSeed"
                                            label="Seed Data Name"
                                            value={basicInfoInput.checkHydraCleanSeed}
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
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.pipelineName}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            error={basicInfoInputCheck.pipelineName}
                            id="pipelineName"
                            name="pipelineName"
                            label="Pipeline Name"
                            value={basicInfoInput.pipelineName}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.pipelineName ? 'The field cannot be empty. Please enter a value' : null}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.projectRoot}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            error={basicInfoInputCheck.projectRoot}
                            id="projectRoot"
                            name="projectRoot"
                            label="Project Root Folder Name"
                            value={basicInfoInput.projectRoot}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.projectRoot ? 'The field cannot be empty. Please enter a value' : null}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>
            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <FormControlLabel
                    className={clsx(classes.margin, classes.textField, classes.withoutLabel)}
                    control={<Checkbox checked={basicInfoInput.checkOwnDataPath} onChange={handleCheckboxChange} name="checkOwnDataPath" />}
                    label={<Typography variant='body2'> Edit your own data input path?</Typography>}
                />
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.inputdatapath}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            disabled={!basicInfoInput.checkOwnDataPath}
                            error={basicInfoInputCheck.inputdatapath}
                            id="inputdatapath"
                            name="inputdatapath"
                            label="Input Data Path"
                            value={basicInfoInput.inputdatapath}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.inputdatapath ? 'The field cannot be empty. Please enter a value' : ('Default Input test data source path: ~/ctap/data/test_data')}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>



            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.eegType}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            error={basicInfoInputCheck.eegType}
                            id="eegType"
                            name="eegType"
                            label="EEG Data Type"
                            value={basicInfoInput.eegType}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.eegType ? 'The field cannot be empty. Please enter a value' : null}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>

                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.sbj_filt}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            error={basicInfoInputCheck.sbj_filt}
                            id="sbj_filt"
                            name="sbj_filt"
                            label="EEG File Name Sequence"
                            value={basicInfoInput.sbj_filt}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.sbj_filt ? 'The field cannot be empty. Please enter a value' : null}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>
            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.eegChanloc}</Typography>} classes={{ tooltip: classes.customWidth }} placement="top">
                        <Autocomplete
                            freeSolo
                            selectOnFocus
                            clearOnBlur
                            handleHomeEndKeys
                            value={basicInfoInput.eegChanloc}
                            onChange={(event, newValue) => {
                                if (JSON.stringify(newValue).slice(1, 5).trim() === 'Add') {
                                    setValue(JSON.stringify(newValue).slice(7, -3).trim());
                                } else {
                                    setValue(newValue)
                                }
                            }}
                            filterOptions={(options, params) => {
                                const filtered = filter(options, params);
                                if (params.inputValue !== '') {
                                    filtered.push(`Add "${params.inputValue}"`);
                                }
                                return filtered;
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
                </FormControl>
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.eegReference}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            error={basicInfoInputCheck.eegReference}
                            id="eegReference"
                            name="eegReference"
                            label="EEG Data Reference Channel"
                            value={basicInfoInput.eegReference}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.eegReference ? 'The field cannot be empty. Please enter a value' : null}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>
            </div>
            <div style={{ marginTop: '0.8rem' }}>
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.eegHeogChannelNames}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            error={basicInfoInputCheck.eegHeogChannelNames}
                            id="eegHeogChannelNames"
                            name="eegHeogChannelNames"
                            label="HEOG Channel Names"
                            value={basicInfoInput.eegHeogChannelNames}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.eegHeogChannelNames ? 'The field cannot be empty. Please enter a value' : null}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>
                <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                    <Tooltip title={<Typography variant='body2'>{helperText.eegVeogChannelNames}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            error={basicInfoInputCheck.eegVeogChannelNames}
                            id="eegVeogChannelNames"
                            name="eegVeogChannelNames"
                            label="VEOG Channel Names"
                            value={basicInfoInput.eegVeogChannelNames}
                            onChange={e => handleInput(e)}
                            type="text"
                            helperText={basicInfoInputCheck.eegVeogChannelNames ? 'The field cannot be empty. Please enter a value' : null}
                            variant="outlined"
                        />
                    </Tooltip>
                </FormControl>
            </div>
        </div>
    )
};

export default BasicInfo;
