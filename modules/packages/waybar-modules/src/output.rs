use serde::Serialize;

#[derive(Serialize)]
pub struct Status {
    pub text: String,
    pub alt: String,
    pub tooltip: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub class: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub percentage: Option<u8>,
}

impl Status {
    pub fn new(
        alt: impl Into<String>,
        text: impl Into<String>,
        tooltip: impl Into<String>,
    ) -> Self {
        Self {
            alt: alt.into(),
            text: text.into(),
            tooltip: tooltip.into(),
            class: None,
            percentage: None,
        }
    }
}
