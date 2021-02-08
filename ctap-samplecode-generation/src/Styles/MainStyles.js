import { makeStyles } from '@material-ui/core/styles';

export const MainStyles = makeStyles((theme) => ({
    formControl: {
        margin: theme.spacing(1),
        width:'25ch'
    },
    selectEmpty: {
        marginTop: theme.spacing(2),
    },

    button: {
        margin: theme.spacing(2),
    },
    nav: {
        color: 'inherit',
        textDecoration: "underline",
        fontStyle: "italic"
    }
}));