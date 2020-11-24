import React, { useState, useEffect, useReducer } from "react";
import { Link } from "react-router-dom";
import TextField from '@material-ui/core/TextField';
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
    root: {
        '& .MuiTextField-root': {
            margin: theme.spacing(1),
            width: '35ch'
        },
    },
}));



const BasicInfo = ({ InputValue, handleInput }) => {
    let classes = useStyles();
    return (
        <form className={classes.root} noValidate autoComplete="off">
            <div>
                <TextField
                    id="pipelineName"
                    name="pipelineName"
                    label="Pipeline Name"
                    value={InputValue.pipelineName}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="Name a folder which contains outputs of corresponding pipes"
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    id="projectRoot"
                    name="projectRoot"
                    label="Project Root"
                    value={InputValue.projectRoot}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="The root directory of the current analysis."
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    id="sbj_filt"
                    name="sbj_filt"
                    label="EEG File Name Sequence"
                    value={InputValue.sbj_filt}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="The unique sequence number in EEG dataset name(sbj_filt)"
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    id="eegType"
                    name="eegType"
                    label="EEG Data Type"
                    value={InputValue.eegType}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="EEG Data Type, eg, *.set/*.bdf"
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    id="eegChanloc"
                    name="eegChanloc"
                    label="EEG Data Channel Location"
                    value={InputValue.eegChanloc}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="Channel Location of testing EEG data "
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    id="eegReference"
                    name="eegReference"
                    label="EEG Data Reference Channel"
                    value={InputValue.eegReference}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="Reference channel of testing EEG data,  eg, {'L_MASTOID' 'R_MASTOID'}"
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    id="eegVeogChannelNames"
                    name="eegVeogChannelNames"
                    label="VEOG Channel Names"
                    value={InputValue.eegVeogChannelNames}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="VEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'VEOG1','VEOG2'}"
                    variant="outlined"
                />
            </div>
            <div>
                <TextField
                    id="eegHeogChannelNames"
                    name="eegHeogChannelNames"
                    label="HEOG Channel Names"
                    value={InputValue.eegHeogChannelNames}
                    onChange={e => handleInput(e)}
                    type="text"
                    helperText="HEOG Channel Names of testing EEG data, required if performing blinks detection, eg, {'HEOG1','HEOG2'}"
                    variant="outlined"
                />
            </div>
        </form>
    )
};

export default BasicInfo;
